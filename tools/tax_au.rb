#!/usr/bin/env ruby
# Simple CLI to compare Australian income tax + 2% Medicare levy
# Usage: ruby opencode/tools/tax_au.rb income:200000 people:2

require 'bigdecimal'
require 'bigdecimal/util'

def usage
  puts <<~USAGE
    Usage: tax_au.rb income:<AUD_total_gross_including_super> people:<int>
    Example: ruby opencode/tools/tax_au.rb income:200000 people:2
    The income amount is the gross total INCLUDING employer superannuation.
    By default the script assumes employer super is 12% of salary (i.e. gross = salary + 12% super).
    Computes even split per person, income tax (ATO resident rates 2025-26) and a 2% Medicare levy per person.
  USAGE
  exit 1
end

args = ARGV.each_with_object({}) do |a, h|
  key, val = a.split(':', 2)
  h[key] = val
end

income = args['income'] || args['income:AUD']
people = args['people']

usage if income.nil? || people.nil?

begin
  total_income = BigDecimal(income.to_s)
  num_people = Integer(people)
rescue StandardError
  puts 'Invalid arguments'
  usage
end

if num_people < 1
  puts 'people must be >= 1'
  exit 1
end

income_per_person = total_income / num_people

# Determine if caller asked for max super
max_super_flag = args.key?('max') || args.key?('max_super') || args.key?('max-super')

# Compute salary (taxable) and employer super contribution per person
if max_super_flag
  super_per_person = BigDecimal('30000')
  salary_per_person = income_per_person - super_per_person
else
  # income includes super at standard rate of 12%: total = salary * 1.12
  salary_per_person = income_per_person / BigDecimal('1.12')
  super_per_person = salary_per_person * BigDecimal('0.12')
end

if salary_per_person <= 0
  puts 'Calculated salary per person is non-positive (income too small relative to super).'
  exit 1
end

# Australian resident tax rates (2025-26 per ATO table)
# Source: https://www.ato.gov.au/tax-rates-and-codes/tax-rates-australian-residents#ato-Australianresidenttaxrates2020to2026
# Implemented as marginal brackets (taxable income in AUD)
BRACKETS = [
  { min: 0,       max: 18_200,  rate: 0.0 },
  { min: 18_200,  max: 45_000,  rate: 0.16 },
  { min: 45_000,  max: 135_000, rate: 0.30 },
  { min: 135_000, max: 190_000, rate: 0.37 },
  { min: 190_000, max: Float::INFINITY, rate: 0.45 }
]

def compute_income_tax(taxable, brackets)
  tax = BigDecimal('0')
  brackets.each do |b|
    lower = BigDecimal(b[:min].to_s)
    upper = b[:max].finite? ? BigDecimal(b[:max].to_s) : nil
    rate = BigDecimal(b[:rate].to_s)

    next if taxable <= lower

    portion = if upper
                [taxable, upper].min - lower
              else
                taxable - lower
              end

    tax += portion * rate
    break if upper && taxable <= upper
  end
  tax
end

medicare_rate = BigDecimal('0.02')

# Helper to format monetary values with 2 decimal places and thousands separators
def money(x)
  s = format('%.2f', x)
  sign = s.start_with?('-') ? '-' : ''
  s = s.sub('-', '')
  int, frac = s.split('.')
  int_commas = int.reverse.scan(/\d{1,3}/).join(',').reverse
  "#{sign}#{int_commas}.#{frac}"
end

tax_per_person = compute_income_tax(salary_per_person, BRACKETS)
medicare_per_person = (salary_per_person * medicare_rate)
super_tax_per_person = (super_per_person * BigDecimal('0.15'))

total_tax_per_person = tax_per_person + medicare_per_person
net_salary_per_person = salary_per_person - total_tax_per_person
net_super_per_person = super_per_person - super_tax_per_person
total_tax_all = (total_tax_per_person + super_tax_per_person) * num_people
net_all = (net_salary_per_person + net_super_per_person) * num_people

puts 'Australian Tax'
puts '--------------'
puts "Total gross income: AUD #{money(total_income)}"
puts "People: #{num_people} (even split)"
puts "Gross per person (including super): AUD #{money(income_per_person)}"
puts "  Gross salary (taxable) per person: AUD #{money(salary_per_person)}"
puts
puts 'Per-person breakdown'
puts "  Income tax:          AUD #{money(tax_per_person)}"
puts "  Medicare 2%:         AUD #{money(medicare_per_person)}"
puts "  Total tax (salary):  AUD #{money(total_tax_per_person)}"
puts "  Net salary (after tax): AUD #{money(net_salary_per_person)}"
puts "  Employer super:      AUD #{money(super_per_person)}"
puts "  Super tax (15%):     AUD #{money(super_tax_per_person)}"
puts "  Net super (in fund): AUD #{money(net_super_per_person)}"
puts "  Total net benefit:   AUD #{money(net_salary_per_person + net_super_per_person)}"
puts
puts 'Aggregate totals'
puts "  Total tax (all, incl. super tax): AUD #{money(total_tax_all)}"
puts "  Net income + super (all): AUD #{money(net_all)}"
