# This only helps if the periods are equally spaced and the exponents are
def rational_zeros(coefficients)
  # Ensure coefficients are for a valid polynomial
  raise ArgumentError, "Coefficients array cannot be empty" if coefficients.empty?

  # Helper method to find all factors (positive and negative) of a number
  def factors(n)
    n = n.abs
    (1..n).each_with_object([]) do |i, facs|
      facs << i << -i if n % i == 0
    end.uniq
  end

  # Extract leading coefficient and constant term
  leading_coefficient = coefficients.first
  constant_term = coefficients.last

  # Find factors of leading coefficient and constant term
  p_factors = factors(constant_term)
  q_factors = factors(leading_coefficient)

  # Generate all possible rational candidates p/q
  candidates = p_factors.product(q_factors).map { |p, q| Rational(p, q) }.uniq

  # Select candidates that are actual roots
  rational_zeros = candidates.select do |candidate|
    coefficients.each_with_index.sum { |coef, idx| coef * candidate**(coefficients.size - 1 - idx) }.zero?
  end

  rational_zeros
end
