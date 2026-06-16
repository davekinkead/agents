#!/usr/bin/env ruby
# P&L style Cyprus company breakdown for non-dom owners (salary + dividends)
# Usage: ruby tax_cyprus.rb income:<EUR_total_gross> people:<int>
# Note: salary per person is fixed to the tax-free band (€19,500) and cannot be changed.

require 'bigdecimal'
require 'bigdecimal/util'

def usage
  puts "Usage: tax_cyprus.rb income:<EUR_total_gross> people:<int> [salary:<per_person_salary>]"
  exit 1
end

args = ARGV.each_with_object({}) do |a, h|
  key, val = a.split(':', 2)
  h[key] = val || true
end

income = args['income']
people = args['people']

usage if income.nil? || people.nil?

begin
  total_income = BigDecimal(income.to_s)
  num_people = Integer(people)
  # Fixed salary per person = tax-free band (€19,500)
  salary_per_person = BigDecimal('19500')
rescue StandardError
  puts 'Invalid arguments'
  usage
end

if num_people < 1
  puts 'people must be >=1'
  exit 1
end

# Rates / caps (kept minimal)
SI_EMP_RATE = BigDecimal('0.088')        # employee social insurance
SI_EMPLOYER_RATE = BigDecimal('0.088')  # employer social insurance
EMPLOYER_REDUNDANCY = BigDecimal('0.012')
EMPLOYER_SOCIAL_COHESION = BigDecimal('0.02')
EMPLOYER_TRAINING = BigDecimal('0.005')
GHS_EMP_RATE = BigDecimal('0.0265')     # employee GHS (applies to salary+dividend)
GHS_EMPLOYER_RATE = BigDecimal('0.029') # employer GHS on salary
GHS_CAP_BASE = BigDecimal('180000')
GHS_CAP_AMOUNT = GHS_CAP_BASE * GHS_EMP_RATE
CIT_RATE = BigDecimal('0.15')

def money(x)
  s = format('%.2f', x)
  int, frac = s.split('.')
  int_commas = int.reverse.scan(/\d{1,3}/).join(',').reverse
  "#{int_commas}.#{frac}"
end

# Basic P&L
total_salary = salary_per_person * num_people

# Employer charges per person
employee_si = [salary_per_person, GHS_CAP_BASE].min * SI_EMP_RATE # SI applies up to cap
employer_si = [salary_per_person, GHS_CAP_BASE].min * SI_EMPLOYER_RATE
employer_extra = salary_per_person * (EMPLOYER_REDUNDANCY + EMPLOYER_SOCIAL_COHESION + EMPLOYER_TRAINING)
employer_ghs_salary = [salary_per_person, GHS_CAP_BASE].min * GHS_EMPLOYER_RATE
total_employer_charges_per_person = employer_si + employer_extra + employer_ghs_salary
total_employer_charges = total_employer_charges_per_person * num_people

# Profit before CIT
pre_cit_profit = total_income - total_salary - total_employer_charges
pre_cit_profit = BigDecimal('0') if pre_cit_profit < 0

# CIT and dividend pool (non-dom owners: no SDC on dividends)
cit_total = pre_cit_profit * CIT_RATE
dividend_pool = pre_cit_profit - cit_total
dividend_pool = BigDecimal('0') if dividend_pool < 0
dividend_per_person = dividend_pool / num_people

# Employee GHS (employee share) applied to salary + dividend, capped per person
ghs_base_per_person = salary_per_person + dividend_per_person
ghs_raw = ghs_base_per_person * GHS_EMP_RATE
ghs_employee = [ghs_raw, GHS_CAP_AMOUNT].min

# Prorate GHS between salary and dividend portions
prorated_ghs_salary = ghs_base_per_person > 0 ? (ghs_employee * (salary_per_person / ghs_base_per_person)) : BigDecimal('0')
prorated_ghs_dividend = ghs_employee - prorated_ghs_salary
prorated_ghs_dividend = BigDecimal('0') if prorated_ghs_dividend < 0

# Net per person (no PIT for non-dom model assumed)
net_salary_per_person = salary_per_person - employee_si
net_dividend_per_person = dividend_per_person - prorated_ghs_dividend
net_total_per_person = net_salary_per_person + net_dividend_per_person

# Totals
total_net_to_owners = net_total_per_person * num_people
# Total costs defined as the difference between gross revenue and net returned to owners.
# Dividends are distributions, not an expense; the user requested total costs = Gross - Net.
total_costs = total_income - total_net_to_owners

puts 'Cyprus P&L (non-dom owners) — Summary'
puts '-----------------------------------'
puts "Revenue: € #{money(total_income)}"
puts "- Salaries (total): € #{money(total_salary)}"
puts "- Employer charges (total): € #{money(total_employer_charges)}"
puts "= Profit before tax: € #{money(pre_cit_profit)}"
puts "- Corporate tax (CIT @ #{(CIT_RATE*100).to_f}%): € #{money(cit_total)}"
puts "= Dividends pool (after CIT): € #{money(dividend_pool)}"
puts
puts 'Per-owner (approx)'
puts "  Gross salary: € #{money(salary_per_person)}"
puts "  Employee SI: € #{money(employee_si)}"
puts "  Net salary: € #{money(net_salary_per_person)}"
puts "  Gross dividend: € #{money(dividend_per_person)}"
puts "  Employee GHS on dividend (prorated): € #{money(prorated_ghs_dividend)}"
puts "  Net dividend: € #{money(net_dividend_per_person)}"
puts "  Net total per owner: € #{money(net_total_per_person)}"
puts
puts 'Totals'
puts "  Total net to owners: € #{money(total_net_to_owners)}"
puts "  Total costs (Gross − Net): € #{money(total_costs)}"
exit 0
