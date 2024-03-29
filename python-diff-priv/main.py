"""Prototype of differential privacy system for eventual implementation on a Lattice ice40 FPGA
Gregory Brooks 2018


Based on the following references:

Choi, Woo-Seok & Tomei, Matthew & Rodrigo Sanchez Vicarte, Jose & Kumar Hanumolu, Pavan & Kumar, Rakesh. (2018).
Guaranteeing Local Differential Privacy on Ultra-Low-Power Systems. 561-574. 10.1109/ISCA.2018.00053.

Christian de Schryver, Daniel Schmidt, Norbert Wehn, et al., “A Hardware Efficient Random Number Generator for
Nonuniform Distributions with Arbitrary Precision,” International Journal of Reconfigurable Computing, vol. 2012,
Article ID 675130, 11 pages, 2012.
"""

from random import getrandbits, random
from dataclasses import dataclass
import itertools
from bitarray import bitarray
import numpy as np
import matplotlib.pyplot as plt
import math

DEBUG = True


@dataclass
class RandFloat:
    """m bit floating point representation used by de Schryver et al.

    symm     -- symmetry bit indicates which half of a symmetrical ICDF the random value lies within
    part     -- part bit splits the encoded half of the ICDF into two parts
    exponent -- m - mant_bw - 2 bits
    mantissa -- mant_bw bits
    m        -- number of bits in floating point representation
    mant_bw  -- number of bits in mantissa
    """
    symm: bool
    part: bool
    exponent: int
    mantissa: int
    m: int
    mant_bw: int

    def to_bits(self):
        """Convert object to m bit representation"""
        bits = (self.exponent << self.mant_bw) + self.mantissa
        bits |= (self.part << self.m - 2)
        bits |= (self.symm << self.m - 1)
        return bits


class CxLookup:
    """Laplace distribution ICDF lookup (simulate ROM on FPGA)"""
    def __init__(self, rng_data):
        self.num_sect = rng_data.growing_oct + rng_data.diminishing_oct
        self.num_subsect = 2**rng_data.k
        length = self.num_sect * self.num_subsect

        mu = 0
        b = 1
        self.k = rng_data.k

        remaining_mant_bits = rng_data.mant_bw - rng_data.k

        self.c0 = [0]*length
        self.c1 = [0]*length

        # First generate c0
        # Smallest division within smallest subsection for part = false
        min_x_coord = (1 / 2**(rng_data.growing_oct + 1))  # Octave width
        min_x_coord /= self.num_subsect  # Subsection width
        min_x_coord /= 2**remaining_mant_bits  # Mantissa division width

        max_abs = 0 - self.icdf_laplace_double(min_x_coord)
        scale_exp = rng_data.By - 1 - math.ceil(math.log2(max_abs))
        max_out = self.icdf_laplace_int(min_x_coord, scale_exp, mu, b)

        for section in range(0, self.num_sect):
            part = False

            if section == rng_data.growing_oct - 1:
                # Section closest to zero is same width as the one after
                part = False
                octave_width = 2**(-(section + 2))
                octave_bound = octave_width  # Upper bound
            elif section == self.num_sect - 1:
                part = True
                exp = section - rng_data.growing_oct
                octave_width = 2**(-(exp + 2))
                octave_bound = 0.5 - octave_width  # Lower bound
            else:
                exp = section
                part = False

                if section >= rng_data.growing_oct:
                    exp -= rng_data.growing_oct
                    part = True

                octave_width = 2**(-(exp + 3))
                if part:
                    octave_bound = 0.5 - 2**(-(exp + 2))  # Lower bound
                else:
                    octave_bound = 2**(-(exp + 2))  # Upper bound

            for subsection in range(0, self.num_subsect):
                # Calculate c0 from ICDF for each subsection boundary in the section
                subsection_width = octave_width / self.num_subsect
                if part:
                    x_coord = octave_bound + (subsection + 1) * subsection_width
                else:
                    x_coord = octave_bound - subsection * subsection_width

                index = self.addr(section, subsection)
                self.c0[index] = self.icdf_laplace_int(x_coord, scale_exp, mu, b)
                if DEBUG:
                    plt.plot(x_coord, -self.c0[index], 'r+')

        # Now generate c1
        for i in range(0, length):
            if i == rng_data.growing_oct * self.num_subsect - 1:
                # Subsection containing zero asymptote
                self.c1[i] = round((max_out - self.c0[i]) / (2**remaining_mant_bits - 1))
            elif i == rng_data.growing_oct * self.num_subsect:
                # First subsection in part == 1 region
                self.c1[i] = (self.c0[0] - self.c0[i]) / 2**remaining_mant_bits
            elif i < rng_data.growing_oct * self.num_subsect:
                # Default for part == 0
                self.c1[i] = (self.c0[i+1] - self.c0[i]) / 2**remaining_mant_bits
            else:
                # Default for part == 1
                self.c1[i] = (self.c0[i-1] - self.c0[i]) / 2**remaining_mant_bits

    @staticmethod
    def icdf_laplace_double(p, mu=0, b=1):
        """Inverse cumulative distribution function for Laplace distribution
        p  -- function input
        mu -- mean of Laplace distribution
        b  -- Laplace distribution scale parameter"""
        return mu - b * np.sign(p - 0.5) * np.log(1 - 2 * abs(p - 0.5))

    def icdf_laplace_int(self, p, scale_exp, mu=0, b=1):
        """Quantised absolute value of ICDF for Laplace distribution

        p         -- function input
        mu        -- mean of Laplace distribution
        b         -- Laplace distribution scale parameter
        scale_exp -- Quantisation step = 2**-scale_exp"""
        return round(2**scale_exp * abs(self.icdf_laplace_double(p, mu, b)))

    def addr(self, section, subsection):
        return section * 2**self.k + subsection

    def lookup(self, section, subsection, select):
        if select:
            return self.c1[self.addr(section, subsection)]
        else:
            return self.c0[self.addr(section, subsection)]

    def interpolate(self, section, subsection, mant_lsbs):
        c_0 = self.lookup(section, subsection, False)
        c_1 = self.lookup(section, subsection, True)
        return c_0 + c_1 * mant_lsbs


class Rng:
    """Simulate fixed point RNG."""
    def __init__(self, Bx, By, k, mant_bw, growing_oct=54, diminishing_oct=4):
        """Initialise object, set the number of bits used by URNG and Laplace output.
        Conversion from URNG to Laplace distribution is described by de Schryver et al.

        # Notation from Choi et al.
        Bx      -- number of random bits generated by the URNG
        By      -- number of random bits in the RNG output (Laplace distribution)

        # Inversion method by de Schryver et al.
        k               -- each 'octave' is divided into 2**k 'subsections'
        mant_bw         -- width of mantissa of floating point URNG output representation
        growing_oct     -- number of growing 'octaves'
        diminishing_oct -- number of diminishing 'octaves'
        """

        self.Bx = Bx
        self.By = By

        self.k = k
        self.mant_bw = mant_bw
        self.exp_bw = self.Bx - 2 - self.mant_bw  # Width of exponent in floating point URNG output representation
        if self.exp_bw < 1:
            raise ValueError("Bx  - 2 - mant_bw must be > 0")
        self.growing_oct = growing_oct  # max exp
        self.diminishing_oct = diminishing_oct  # max exp
        if growing_oct > 2**self.exp_bw:
            raise ValueError("Number of growing octaves cannot exceed address space (2^exp_bw)")
        if diminishing_oct > 2**self.exp_bw:
            raise ValueError("Number of diminishing octaves cannot exceed address space (2^exp_bw)")

        self.min_x = 1 / (2 ** (self.growing_oct + 3))
        self.max_x = 0.5 - 1 / (2 ** (self.diminishing_oct + 3))
        self.quantisation_step = (self.laplace_inv_cdf(self.max_x) - self.laplace_inv_cdf(self.min_x)) / 2 ** self.By

    def urng(self, bits=None):
        """Return a random number from the URNG.

        bits -- (Optional) number of bits in random output. Defaults to value set during Rng.init()
        """
        if bits is None:
            bits = self.Bx
        random_bits = getrandbits(bits)

        if DEBUG:
            print("URNG output: {}".format(bin(random_bits)))
        return random_bits

    def floating_point(self, urand=None):
        """Convert URNG output to floating point form

        urand -- uniform random number
        """
        if urand is None:
            rn = self.urng()
        else:
            rn = urand

        # Boolean values (single bit)
        symm = rn >> (self.Bx - 1)  # MSB
        part = (rn >> (self.Bx - 2)) - symm

        if part:
            max_exp = self.diminishing_oct-1
        else:
            max_exp = self.growing_oct-1

        # Divide up the remaining bits
        exponent_part = self.get_exponent(rn)
        mantissa = self.get_mantissa(rn)

        # Exponent is calculated by counting leading zeros
        leading_zeros = self.count_leading_zeros(exponent_part, self.exp_bw)
        while exponent_part == 0 and leading_zeros < max_exp:
            exponent_part = self.get_exponent(self.urng())
            leading_zeros += self.count_leading_zeros(exponent_part, self.exp_bw)
        exponent = min(leading_zeros, max_exp)

        return RandFloat(symm != 0, part != 0, exponent, mantissa, self.Bx, self.mant_bw)

    def get_exponent(self, rbv):
        """Return exponent bits from random bit vector

        rbv -- random bit vector"""
        return (rbv >> self.mant_bw) & (2**self.exp_bw - 1)

    def get_mantissa(self, rbv):
        """Return mantissa bits from random bit vector

        rbv -- random bit vector"""
        return rbv & (2 ** self.mant_bw - 1)

    def fake_lookup(self, symm, part, exp, mant):
        """Simulate FPGA lookup table that returns linear approximation of inverse CDF for Laplace distribution

        symm -- symmetry bit
        part -- part bit
        exp  -- exponent bits
        mant -- mantissa bits"""
        table = CxLookup(self)
        if part:
            offset = self.growing_oct
        else:
            offset = 0

        section_addr = offset + exp
        subsection_addr = mant >> (self.mant_bw - self.k)

        return table.interpolate(section_addr, subsection_addr, mant & 2**((self.mant_bw-self.k)-1))

    @staticmethod
    def laplace_inv_cdf(p, mu=0, b=1):
        """Inverse cumulative distribution function for Laplace distribution
        p  -- function input
        mu -- mean of Laplace distribution
        b  -- Laplace distribution scale parameter"""
        return mu - b * np.sign(p-0.5) * np.log(1-2*abs(p-0.5))

    @staticmethod
    def count_leading_zeros(val, num_bits):
        """Count leading zeros in val, with maximum num_bits

        val      -- bit array to count leading zeros in
        num_bits -- maximum number of bits in val"""
        # cursor = 2 ** (num_bits - 1)
        local_val = val
        count = 0
        for i in range(0, num_bits):
            if local_val - (local_val >> 1) == 0:
                count += 1
            local_val = local_val >> 1
        return count


class Invariant:
    """Represents a relationship between variables, described in a Newton invariant."""

    # ID bit for a sensor is set to 1 when sensor is read, and not reset until privacy budget is fully replenished.
    read_bitfield = bitarray()

    def __init__(self, fn, sensors):
        """Define relationship between sensor measurements.

        fn      -- mathematical equation relating sensor measurements
        sensors -- measurements being related i.e. arguments to fn.
                    List of unique sensor IDs in the order accepted by self.fn()
        """
        self.fn = fn
        self.sensors = sensors
        # Create bitfield to list all the sensors involved in the invariant
        self.bitfield = bitarray(len(sensors))
        for ID in sensors:
            self.bitfield[ID] = 1


class HardwareSensor:
    """Represents hardware sensor and driver, output is a base Newton signal."""
    def __init__(self, minimum, maximum):
        """Initialise object, set the range of the sensor output.

        minimum -- minimum sensor output
        maximum -- maximum sensor output
        """
        self.min = min(minimum, maximum)  # Ensure max and min are the right way round
        self.max = max(minimum, maximum)
        self.d = self.max - self.min  # Notation from Choi et al.

    def read(self):
        """Simulate reading from the physical sensor."""
        return self.min + self.d * random()  # Return a random value within the sensor range


class Sensor(HardwareSensor):
    """Represents sensor along with additional privacy information supplied along with Newton description.

    minimum    -- minimum sensor output
    maximum    -- maximum sensor output
    budget_max -- privacy budget (units ε)
    rep_rate   -- budget replenishment rate (per arbitrary time uint)
    epsilon    -- privacy factor (smaller value means greater privacy)
    invariants -- list of all nvariants involving the sensor
    """

    next_id = next(itertools.count())

    def __init__(self, minimum, maximum, budget_max, rep_rate, epsilon, invariants):
        super().__init__(minimum, maximum)
        self.budget_max = budget_max
        self.budget = budget_max
        self.rep_rate = rep_rate
        self.epsilon = epsilon
        self.invariants = invariants

        self.id = Sensor.next_id()  # Unique ID
        Invariant.read_bitfield.append(0)
        self.prev_return_value = 0  # Last query response returned

    def query(self):
        """Query a sensor - noised value is returned and appropriate privacy control is performed"""
        noise = random()  # Todo: replace with Laplace(self.d/self.epsilon) noise, using Schryver et al. and Choi et al. techniques

        privacy_loss = 1  # Todo: calculate privacy loss (a function of random value)

        # Todo: calculate privacy loss for all related sensors and perform this check for all of them

        if self.budget > privacy_loss:
            self.budget -= privacy_loss
            Invariant.read_bitfield[self.id] = 1
            true_measurement = super().read()
            self.prev_return_value = true_measurement + noise
            return self.prev_return_value
        else:
            # If insufficient privacy budget, return the last value i.e. no information revealed
            return self.prev_return_value

    def rep_clock(self, number=1):
        """Apply 'number' privacy budget replenishment clock pulses.

        number -- number of pulses to apply, each replenishes the budget by rep_rate
        """
        budget_increase = number * self.rep_rate
        if self.budget < self.budget_max - budget_increase:
            self.budget += budget_increase
        else:
            self.budget = self.budget_max
            Invariant.read_bitfield[self.id] = 0


if __name__ == '__main__':
    # sensor_list = [HardwareSensor(i, 100 + 2*i) for i in range(3)]  # Arbitrary sensors with arbitrary limits
    # rng = Rng(8, 16, 2, 3, 3)
    # print("Floating point URNG output: {}".format(bin(rng.floating_point().to_int())))

    # Test RNG
    rng = Rng(8, 16, 2, 3, 4, 3)
    for i in range(0, 2**7):
        rn = rng.floating_point(i)
        rng.fake_lookup(rn.symm, rn.part, rn.exponent, rn.mantissa)
    # x = np.linspace(rng.min_x, 1-rng.min_x, 100)
    x = np.linspace(rng.min_x, rng.max_x, 100)
    plt.plot(x, rng.laplace_inv_cdf(x)/rng.quantisation_step)
    plt.show()

