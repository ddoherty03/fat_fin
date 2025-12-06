- [Installation](#orge9859da)
- [Usage](#orgbc24849)
  - [`CashPoint` class](#org7403eee)
    - [Constructing a `CashPoint`  object](#orgad1cc9f)
    - [Computing a `CashPoint`'s value on a different date with #value\_on (PV and FV)](#org728f140)
    - [Computing the annualized growth rate between two `CashPoints` with #cagr (CAGR)](#org8703345)
  - [`CashFlow` class](#org1f0af85)
    - [Constructing `CashFlow` object](#orgfacfd0f)
    - [Attributes of a `CashFlow`](#orgb4db8c2)
    - [Computing a `CashFlow`'s value on a different date with `#value_on` (NPV)](#orgb5d392a)
    - [Computing a `CashFlow`'s internal rate of return with `#irr` (IRR)](#org6145cf3)
    - [Computing a `CashFlow`'s a modified internal rate of Return with `#mirr` (MIRR aka MWIRR)](#orgb682b69)
    - [Using Non-Standard Compounding](#org6810bf6)
    - [Subsetting `CashFlow` with `#within(period)`](#org9a8c826)
- [Development](#org1662eed)
- [Contributing](#org38e2e2f)
- [License](#org211b5ee)



<a id="orge9859da"></a>

# Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add fat_fin
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install fat_fin
```


<a id="orgbc24849"></a>

# Usage


<a id="org7403eee"></a>

## `CashPoint` class

This gem, `fat_fin`, defines classes for dealing with certain financial calculations involving the time-value of money. It's base class is `CashPoint` which represents a quantity of money tied to a particular date.


<a id="orgad1cc9f"></a>

### Constructing a `CashPoint`  object

A new `CashPoint` needs an amount and, optionally, a date to be initialized. If no date is given, it uses the `Date.today` as its date.

```ruby
cp1 = FatFin::CashPoint.new(25_000.00, date: '2021-04-18')
```

```
#<FatFin::CashPoint:0x00007f11a01624a8 @amount=25000.0, @date=Sun, 18 Apr 2021>
```

The value for the `date` parameter can be a string parseable as a date with `Date.parse`, a Date object, or any object that responds to the `#to_date` method, including `Time` and `DateTime`.


<a id="org728f140"></a>

### Computing a `CashPoint`'s value on a different date with #value\_on (PV and FV)

Once created, you can get its time-value as of any other date at any assumed interest rate. For example, at a 5% rate, here is how you would find its value after more than two years.

```ruby
cp1.value_on('2024-09-12', rate: 0.05)
```

```
29510.979573836776
```

The same `value_on` method works equally well for discounting the value back to an earlier date with a different interest rate, 6% this time.

```ruby
cp1.value_on('2020-05-16', rate: 0.06)
```

```
23692.035645041837
```

If no rate is given a 10% rate is (arbitrarily) used and if no date is given, it uses its own date. Here's how the value progresses through time:

```ruby
[[cp1.date.iso, (cp1.date + 2.years).iso, (cp1.date + 4.years).iso], nil,
  [cp1.value_on(cp1.date).commas(2),
   cp1.value_on(cp1.date + 2.years).commas(2),
   cp1.value_on(cp1.date + 4.years).commas(2)]
  ]
```

```
| 2021-04-18 | 2023-04-18 | 2025-04-18 |
|------------+------------+------------|
|  25,000.00 |  30,250.00 |  36,602.50 |
```

I used the `#commas` method from my `fat_core` gem to make the numbers more readable.

Besides varying the valuation date and the rate used, the `#value_on` method also allows you to optionally specify the number of compounding periods per year with the `freq:` parameter.

```ruby
[[0, 1, 2, 3, 4, 6, 12, :cont], nil,
[
  cp1.value_on('2024-09-12', freq: 0).commas(2),
  cp1.value_on('2024-09-12', freq: 1).commas(2),
  cp1.value_on('2024-09-12', freq: 2).commas(2),
  cp1.value_on('2024-09-12', freq: 3).commas(2),
  cp1.value_on('2024-09-12', freq: 4).commas(2),
  cp1.value_on('2024-09-12', freq: 6).commas(2),
  cp1.value_on('2024-09-12', freq: 12).commas(2),
  cp1.value_on('2024-09-12', freq: :cont).commas(2),
]]
```

```
|         0 |         1 |         2 |         3 |         4 |         6 |        12 |     :cont |
|-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------|
| 33,500.00 | 34,568.07 | 34,835.92 | 34,929.51 | 34,977.16 | 35,025.40 | 35,074.24 | 35,123.69 |
```

The frequency must evenly divide 12:

```ruby
cp1.value_on('2024-09-12', freq: 5)
```

```
=> false
ArgumentError: Frequency (5) must be a divisor of 12 or :cont. (ArgumentError)

      raise ArgumentError, "Frequency (#{freq}) must be a divisor of 12 or :cont." unless valid_freq?(freq)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
from /home/ded/src/fat_fin/lib/fat_fin/cash_point.rb:58:in 'FatFin::CashPoint#value_on'
:org_babel_ruby_eoe
```

But what about the other two frequencies, 0 and :cont? A frequency of 0 is taken as a request to use simple interest. That means that not only does interest *not* compound yearly nor many times a year, but that it *does not compound at all*. Simple interest of 10% for three years amounts to 30% (10% \* 3), while the same interest compounded annually works out closer to 33.1% ($(1 + 0.1)^3 = 1.1^3 = 1.331$)

As for the special frequency represented by the symbol `:cont`, it goes to the opposite extreme: compounding continuously. Though compounding 12 times per year results in a higher rate than compounding 2 times per year, more frequent compounding settles to a limit represented by the exponential function. That is, compounding a 10% annual rate continuously for 3 years works out to around 34.986%, given by the formula $e^{rt}$ where $r$ is the annual interest rate and $t$ is the number of years interest: $e^{(0.1 * 3)} = e^{(0.3)} = 1.34985880758$.


<a id="org8703345"></a>

### Computing the annualized growth rate between two `CashPoints` with #cagr (CAGR)

One measure of how well an investment that has grown from one value on one date to a larger (hopefully) value on a later date is the CAGR, or "Cummulative Annual Growth Rate." It answers the question: in order for my investment to have grown so much in such-and-such a time, what *annually compounding* interest rate would I have had to earn? A high CAGR indicates a good annual equivalent return, and a low or even negative CAGR indicates poor performance.

The `CashPoint` class provides a `#cagr` method to measure the CAGR between two `CashPoints`. Recall that our `cp1` value is 25\_000.00 on 2021-04-18. What CAGR would it represent if it had started out two years earlier as 15\_000, 17\_000, etc?

```ruby
results = []
results << ["Start Value", "CAGR"]
results << nil
(15_000..30_000).step(2_000) do |val0|
  cp0 = FatFin::CashPoint.new(val0, date: cp1.date - 2.years)
  results << [ val0.commas(2), cp1.cagr(cp0).round(5) ]
end
results
```

```
| Start Value |     CAGR |
|-------------+----------|
|   15,000.00 |  0.29099 |
|   17,000.00 |  0.21268 |
|   19,000.00 |  0.14708 |
|   21,000.00 |  0.09109 |
|   23,000.00 |  0.04257 |
|   25,000.00 |      0.0 |
|   27,000.00 | -0.03775 |
|   29,000.00 | -0.07152 |
```

Had we started with only 15\_000 two years earlier, the CAGR would have been a very favorable 29%, but it can go the other way too: had we started with 29\_000, it would indicate a negative growth of over 7%.


<a id="org1f0af85"></a>

## `CashFlow` class

While the `CashPoint` class represents a single value at a single point of time, sometimes we want to analyze a whole sequence of `CashPoints`, and this is what the `CashFlow` class provides.


<a id="orgfacfd0f"></a>

### Constructing `CashFlow` object

A `CashFlow` object consists of a collection of `CashPoint` objects that can be passed to the initializer as an array or can be added to it after creation with an `add_cash_point` method or its equivalent, the `<<` shovel operator.

Suppose one wanted to model an investment that requires a $40,000 up front investment and a $5,000 investment after 18 months. It promises to earn $2,000 per month for 20 months, then pays a salvage value of $15,000 at the end of that time.

```ruby
# Upfront costs
start_date = Date.parse('2022-01-15')
cps = [
  FatFin::CashPoint.new(-40_000, date: start_date),
  FatFin::CashPoint.new(-5_000, date: start_date + 18.months),
]
flow = FatFin::CashFlow.new(cps)

# Add additional CashPoints representing the earnings with the << shovel
# operator
earn_date = start_date + 1.month
20.times do |k|
  flow << FatFin::CashPoint.new(2_000, date: earn_date + k.months)
end

# Add the salvage value at the end with the add_cash_point method.
flow.add_cash_point(FatFin::CashPoint.new(15_000, date: earn_date + 21.months))

# Format it all as a table
tab = [["Date", "Amount"], nil]
flow.cash_points.each do |cp|
  tab << [cp.date.iso, cp.amount.commas(2)]
end
tab
```

```
| Date       |     Amount |
|------------+------------|
| 2022-01-15 | -40,000.00 |
| 2022-02-15 |   2,000.00 |
| 2022-03-15 |   2,000.00 |
| 2022-04-15 |   2,000.00 |
| 2022-05-15 |   2,000.00 |
| 2022-06-15 |   2,000.00 |
| 2022-07-15 |   2,000.00 |
| 2022-08-15 |   2,000.00 |
| 2022-09-15 |   2,000.00 |
| 2022-10-15 |   2,000.00 |
| 2022-11-15 |   2,000.00 |
| 2022-12-15 |   2,000.00 |
| 2023-01-15 |   2,000.00 |
| 2023-02-15 |   2,000.00 |
| 2023-03-15 |   2,000.00 |
| 2023-04-15 |   2,000.00 |
| 2023-05-15 |   2,000.00 |
| 2023-06-15 |   2,000.00 |
| 2023-07-15 |  -3,000.00 |
| 2023-08-15 |   2,000.00 |
| 2023-09-15 |   2,000.00 |
| 2023-11-15 |  15,000.00 |
```


<a id="orgb4db8c2"></a>

### Attributes of a `CashFlow`

1.  First and Last Dates

    Once constructed, you can query for certain attributes of a `CashFlow` object. For one, you can get its first and last date:
    
    ```ruby
    [[ 'First', 'Last'],
    nil,
    [flow.first_date.iso,
    flow.last_date.iso]]
    ```
    
    ```
    | First      | Last       |
    |------------+------------|
    | 2022-01-15 | 2023-11-15 |
    ```

2.  Years Between First and Last

    Using the `#years` method, you can get the number of years between the first and last `CashPoint` in the `CashFlow`. The number of years is expressed as a floating point number computed as the number of days between the first and last ~CashPoint~s divided by 365.25
    
    ```ruby
    flow.years
    ```
    
    ```
    1.8316221765913758
    ```

3.  Number of CashPoints

    The method `#size` returns the number of `CashPoint~s in the ~CashFlow`:
    
    ```ruby
    flow.size
    ```
    
    ```
    22
    ```

4.  Extracting the Dates, Values and CashPoints

    You may want to extract the dates, values, or individual `CashPoint` objects:
    
    ```ruby
    flow.dates.map { |d| [d.iso] }
    ```
    
    ```
    | 2022-01-15 |
    | 2022-02-15 |
    | 2022-03-15 |
    | 2022-04-15 |
    | 2022-05-15 |
    | 2022-06-15 |
    | 2022-07-15 |
    | 2022-08-15 |
    | 2022-09-15 |
    | 2022-10-15 |
    | 2022-11-15 |
    | 2022-12-15 |
    | 2023-01-15 |
    | 2023-02-15 |
    | 2023-03-15 |
    | 2023-04-15 |
    | 2023-05-15 |
    | 2023-06-15 |
    | 2023-07-15 |
    | 2023-08-15 |
    | 2023-09-15 |
    | 2023-11-15 |
    ```
    
    ```ruby
    flow.amounts.map { |d| [d] }
    ```
    
    ```
    | -40000.0 |
    |  -3000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |   2000.0 |
    |  15000.0 |
    ```


<a id="orgb5d392a"></a>

### Computing a `CashFlow`'s value on a different date with `#value_on` (NPV)

Just as you can compute the time-value of a single `CashPoint` to any date at any given rate, so you can do the same to a whole collection of `CashPoints` with the `value_on` method of `CashFlow`. When the value of a collection of `CashPoints` is taken as of the date of the first such payment, it is called the "Net Present Value," or NPV, of the stream of payments.

In the above example, payments out are represented by negative numbers and receipts are represented by positive numbers.

We can calculate the NPV of the above stream by applying the `value_on` for the first date to the `CashFlow` object:

```ruby
flow.value_on(flow.first_date, rate: 0.05)
```

```
7408.20205951782
```

By default, the date used in the as the first parameter to `#value_on` is the date of the earliest `CashPoint` in the collection, i.e., it is the NPV.

```ruby
flow.value_on(rate: 0.05)
```

```
7408.20205951782
```

Also, if no rate is given, it uses 10%, with a compunding frequency of once per year.

```ruby
flow.value_on
```

```
5099.32905180526
```

But we can compute the `CashFlow`'s value as of any date using any rate:

```ruby
flow.value_on('2019-01-01', rate: 0.05)
```

```
6387.352638966449
```

And we can use any valid compounding frequency as explained above for `CashPoints`:

```ruby
flow.value_on('2019-01-01', rate: 0.05, freq: :cont)
```

```
6310.6520206276355
```


<a id="org6145cf3"></a>

### Computing a `CashFlow`'s internal rate of return with `#irr` (IRR)

One common statistic that investors want to compute with respect to a `CashFlow` is the rate that would cause its NPV to equal zero, called the "Internal Rate of Return," or IRR.

```ruby
flow.irr
```

```
0.23407936516476974
```

Here, we see that the IRR for the flow is around 23.4%. The IRR calculation uses a numerical method called the Newton-Raphson method for finding the IRR, and it involves providing an initial guess and improving the guess at each step. You can have the `#irr` method report the details of its progress by adding a `verbose: true` parameter to the call:

```ruby
flow.irr(verbose: true)
```

```
=> false
Newton-Raphson search (eps = 1.0e-07):
------------------------------
Iter: 1, Guess: 0.12092767; NPV: 4206.386526984578; NPV': -45461.666615201437
Iter: 2, Guess: 0.21345368; NPV: 697.048906222535; NPV': -35056.155521122069
Iter: 3, Guess: 0.23333746; NPV: 24.591008237110; NPV': -33189.475299724581
Iter: 4, Guess: 0.23407839; NPV: 0.032366772653; NPV': -33122.088502503138
------------------------------
=> 0.23407936516476974
:org_babel_ruby_eoe
```

The `#irr` method uses an estimated guess for IRR based on ratio of inflows to outflows over the period of this CashFlow., as the initial guess, but you can supply a different one with the `guess:` parameter:

```ruby
# load('/home/ded/src/fat_fin/lib/fat_fin.rb')
flow.irr(guess: 10, verbose: true)
```

```
=> false
Newton-Raphson search (eps = 1.0e-07):
------------------------------
Iter: 1, Guess: 10.00000000; NPV: -31076.312232674070; NPV': 2466.934938552309
Iter: 2, Guess: 22.59713491; NPV: -33396.093041699598; NPV': 1316.229437724939
Iter: 3, Guess: 47.96968173; NPV: -34788.881906937699; NPV': 678.649928872439
Iter: 4, Guess: 99.23157749; NPV: -35730.986737560910; NPV': 345.396370486952
Iter: 5, Guess: 202.68080218; NPV: -36413.549104543832; NPV': 174.685865661662
Iter: 6, Guess: 411.13240739; NPV: -36931.389566140220; NPV': 88.039337218712
Iter: 7, Guess: 830.61977216; NPV: -37337.647293334659; NPV': 44.275823126973
Iter: 8, Guess: 1673.91628607; NPV: -37664.643358944893; NPV': 22.235655099283
Iter: 9, Guess: 3367.80131850; NPV: -37933.241775182243; NPV': 11.156211869213
Iter: 10, Guess: 6767.99147443; NPV: -38157.540518410096; NPV': 5.593531711310
Iter: 10, Guess: 0.50000000; NPV: -7000.358124150662; NPV': -16235.005275863121
Iter: 11, Guess: 0.06881085; NPV: 6508.871286784465; NPV': -52881.147555498756
Iter: 12, Guess: 0.19189576; NPV: 1456.512225106533; NPV': -37214.016867361112
Iter: 13, Guess: 0.23103457; NPV: 101.147353737904; NPV': -33399.895368673489
Iter: 14, Guess: 0.23406294; NPV: 0.544028052382; NPV': -33123.491890867852
Iter: 15, Guess: 0.23407936; NPV: 0.000015873873; NPV': -33121.999771027127
------------------------------
=> 0.23407936468721136
:org_babel_ruby_eoe
```

But be careful, a bad initial guess can cause the algorithm to spin out of control, but the `#irr` method tries to detect this and adjust the guess if it sees the guesses exploding:

```ruby
flow.irr(guess: 7, verbose: true)
```

```
=> false
Newton-Raphson search (eps = 1.0e-07):
------------------------------
Iter: 1, Guess: 7.00000000; NPV: -29649.413393915809; NPV': 3070.038462184160
Iter: 2, Guess: 16.65766838; NPV: -32652.745358328237; NPV': 1689.984776927528
Iter: 3, Guess: 35.97899352; NPV: -34318.471305710358; NPV': 879.290608451189
Iter: 4, Guess: 75.00871928; NPV: -35403.915257938366; NPV': 449.240734072502
Iter: 5, Guess: 153.81705649; NPV: -36172.392029706316; NPV': 227.656121869119
Iter: 6, Guess: 312.70754330; NPV: -36746.160852021960; NPV': 114.867018986867
Iter: 7, Guess: 632.60929731; NPV: -37190.985548284778; NPV': 57.809166659572
Iter: 8, Guess: 1275.94992471; NPV: -37545.745333550229; NPV': 29.046058385040
Iter: 9, Guess: 2568.57782058; NPV: -37835.014151742158; NPV': 14.578014028063
Iter: 10, Guess: 5163.92545016; NPV: -38075.126132745208; NPV': 7.310919531686
Iter: 10, Guess: 0.50000000; NPV: -7000.358124150662; NPV': -16235.005275863121
Iter: 11, Guess: 0.06881085; NPV: 6508.871286784465; NPV': -52881.147555498756
Iter: 12, Guess: 0.19189576; NPV: 1456.512225106533; NPV': -37214.016867361112
Iter: 13, Guess: 0.23103457; NPV: 101.147353737904; NPV': -33399.895368673489
Iter: 14, Guess: 0.23406294; NPV: 0.544028052382; NPV': -33123.491890867852
Iter: 15, Guess: 0.23407936; NPV: 0.000015873873; NPV': -33121.999771027127
------------------------------
=> 0.23407936468721136
:org_babel_ruby_eoe
```

This initial guess of 7 caused the iterations to make no progress towards finding a solution. When the algorithm detects that the guesses are going out of control and that the initial guess was not close to the default, it resets it to the default guess and starts over. In this case it was able to recover and get the right answer.


<a id="orgb682b69"></a>

### Computing a `CashFlow`'s a modified internal rate of Return with `#mirr` (MIRR aka MWIRR)

One assumption that the IRR method makes is that amounts coming in accumulate interest or value at the same rate as we should discount values going out. However, this is not always the case. The rate at which one may borrow values going out and the rate at which one may earn on values coming in may be quite different.

$$ \left(\frac{FV}{PV}\right)^{1/y} $$

```ruby
flow.mirr(earn_rate: 0.05, borrow_rate: 0.07, verbose: true)
```

```
=> false
FV of Positive Flow at earn rate (0.05): 54893.43158227642
PV of Negative Flow at borrow rate (0.07): 42710.47613751121
Years from first to last flow: 1.8316221765913758
Modified internal rate of return: 0.14683893480678378
=> 0.14683893480678378
:org_babel_ruby_eoe
```

The `earn_rate` defaults to 5% and the `borrow_rate` defaults to 7% as in the example, but if your using a credit card to borrow, you will surely want to supply better values:

```ruby
flow.mirr(earn_rate: 0.05, borrow_rate: 0.21, verbose: true)
```

```
=> false
FV of Positive Flow at earn rate (0.05): 54893.43158227642
PV of Negative Flow at borrow rate (0.21): 42253.944402704736
Years from first to last flow: 1.8316221765913758
Modified internal rate of return: 0.15358746594066242
=> 0.15358746594066242
:org_babel_ruby_eoe
```


<a id="org6810bf6"></a>

### Using Non-Standard Compounding

The classical NPV analysis always assumes annual compounding of interest, but other assumptions are plausible. So, the `#irr` method can be given a `freq:` parameter like the `#value_on` methods.

Like continuous compounding:

```ruby
flow.irr(freq: :cont, verbose: true)
```

```
=> false
Newton-Raphson search (eps = 1.0e-07):
------------------------------
Iter: 1, Guess: 0.12092767; NPV: 3891.325426358200; NPV': -46309.151771020181
Iter: 2, Guess: 0.20495697; NPV: 220.246951409757; NPV': -41180.328780482501
Iter: 3, Guess: 0.21030532; NPV: 0.814155074298; NPV': -40876.303848376207
Iter: 4, Guess: 0.21032524; NPV: 0.000011227936; NPV': -40875.176412291505
------------------------------
=> 0.21032523851027085
:org_babel_ruby_eoe
```

Or, egad, simple interest:

```ruby
flow.irr(freq: 0, verbose: true)
```

```
=> false
Newton-Raphson search (eps = 1.0e-07):
------------------------------
Iter: 1, Guess: 0.12092767; NPV: 4318.574071153786; NPV': 81713.620972333301
Iter: 2, Guess: 0.06807756; NPV: 6586.158046234209; NPV': 67836.735803142903
Iter: 3, Guess: -0.02901081; NPV: 11665.357047873676; NPV': 50714.678471023704
Iter: 4, Guess: -0.25903015; NPV: 33517.058100536284; NPV': 30062.773713603186
Iter: 5, Guess: -1.37393254; NPV: -101029.481571081764; NPV': 7851.078126045344
Iter: 6, Guess: 11.49429778; NPV: -34125.222496168084; NPV': 94868.235149647400
Iter: 7, Guess: 11.85400957; NPV: -34265.357754967306; NPV': 1126989.807389444904
Iter: 8, Guess: 11.88441389; NPV: -34276.884173015307; NPV': 1797307.222584401257
Iter: 9, Guess: 11.90348513; NPV: -34284.089576685074; NPV': 2577371.969429826830
Iter: 10, Guess: 11.91678709; NPV: -34289.104082501595; NPV': 3466922.340869599953
Iter: 11, Guess: 11.92667745; NPV: -34292.826566676973; NPV': 4465032.296269683167
Iter: 12, Guess: 11.93435775; NPV: -34295.713759741171; NPV': 5570769.661692904308
Iter: 13, Guess: 11.94051412; NPV: -34298.025875855994; NPV': 6783308.623945142142
Iter: 14, Guess: 11.94557036; NPV: -34299.923362442722; NPV': 8101937.695640299469
Iter: 15, Guess: 11.94980391; NPV: -34301.511100827920; NPV': 9526045.853198044002
Iter: 16, Guess: 11.95340472; NPV: -34302.860816203916; NPV': 11055105.992631372064
Iter: 17, Guess: 11.95650762; NPV: -34304.023360876767; NPV': 12688660.242632733658
Iter: 18, Guess: 11.95921114; NPV: -34305.035869777363; NPV': 14426307.885020826012
Iter: 19, Guess: 11.96158909; NPV: -34305.926138604962; NPV': 16267695.648667369038
Iter: 20, Guess: 11.96369792; NPV: -34306.715413386031; NPV': 18212509.946561146528
Iter: 21, Guess: 11.96558161; NPV: -34307.420229454183; NPV': 20260470.648275680840
Iter: 22, Guess: 11.96727493; NPV: -34308.053659554389; NPV': 22411326.052702348679
Iter: 23, Guess: 11.96880577; NPV: -34308.626182496992; NPV': 24664848.798781037331
Iter: 24, Guess: 11.97019676; NPV: -34309.146301156899; NPV': 27020832.512464344501
Iter: 25, Guess: 11.97146649; NPV: -34309.620990752126; NPV': 29479089.035467553884
Iter: 26, Guess: 11.97263035; NPV: -34310.056029663494; NPV': 32039446.117157842964
Iter: 27, Guess: 11.97370122; NPV: -34310.456247368791; NPV': 34701745.478132307529
Iter: 28, Guess: 11.97468995; NPV: -34310.825712857419; NPV': 37465841.174366913736
Iter: 29, Guess: 11.97560573; NPV: -34311.167879628083; NPV': 40331598.206318624318
Iter: 30, Guess: 11.97645646; NPV: -34311.485698559867; NPV': 43298891.329091399908
Iter: 31, Guess: 11.97724889; NPV: -34311.781706699847; NPV': 46367604.028818465769
Iter: 32, Guess: 11.97798889; NPV: -34312.058097780777; NPV': 49537627.637287519872
Iter: 33, Guess: 11.97868154; NPV: -34312.316778726985; NPV': 52808860.562415264547
Iter: 34, Guess: 11.97933128; NPV: -34312.559415304371; NPV': 56181207.616140805185
Iter: 35, Guess: 11.97994203; NPV: -34312.787469281786; NPV': 59654579.424921520054
Iter: 36, Guess: 11.98051722; NPV: -34313.002228896527; NPV': 63228891.910497039557
Iter: 37, Guess: 11.98105990; NPV: -34313.204833995187; NPV': 66904065.830803804100
Iter: 38, Guess: 11.98157277; NPV: -34313.396296909101; NPV': 70680026.372480750084
Iter: 39, Guess: 11.98205825; NPV: -34313.577519887847; NPV': 74556702.788048088551
Iter: 40, Guess: 11.98251848; NPV: -34313.749309737577; NPV': 78534028.071728408337
Iter: 41, Guess: 11.98295541; NPV: -34313.912390175123; NPV': 82611938.668891519308
Iter: 42, Guess: 11.98337077; NPV: -34314.067412304430; NPV': 86790374.214884623885
Iter: 43, Guess: 11.98376614; NPV: -34314.214963540981; NPV': 91069277.299647867680
Iter: 44, Guess: 11.98414293; NPV: -34314.355575247020; NPV': 95448593.255005300045
Iter: 45, Guess: 11.98450244; NPV: -34314.489729290159; NPV': 99928269.961871907115
Iter: 46, Guess: 11.98484583; NPV: -34314.617863699015; NPV': 104508257.675211817026
Iter: 47, Guess: 11.98517417; NPV: -34314.740377558155; NPV': 109188508.864739850163
Iter: 48, Guess: 11.98548844; NPV: -34314.857635259228; NPV': 113968978.069563508034
Iter: 49, Guess: 11.98578953; NPV: -34314.969970205420; NPV': 118849621.765281617641
Iter: 50, Guess: 11.98607826; NPV: -34315.077688049591; NPV': 123830398.242241993546
Iter: 51, Guess: 11.98635537; NPV: -34315.181069533610; NPV': 128911267.493974477053
Iter: 52, Guess: 11.98662156; NPV: -34315.280372984715; NPV': 134092191.114336133003
Iter: 53, Guess: 11.98687747; NPV: -34315.375836516956; NPV': 139373132.203076034784
Iter: 54, Guess: 11.98712368; NPV: -34315.467679977221; NPV': 144754055.278556555510
Iter: 55, Guess: 11.98736075; NPV: -34315.556106670185; NPV': 150234926.197041600943
Iter: 56, Guess: 11.98758916; NPV: -34315.641304890771; NPV': 155815712.078288197517
Iter: 57, Guess: 11.98780939; NPV: -34315.723449288918; NPV': 161496381.236168056726
Iter: 58, Guess: 11.98802188; NPV: -34315.802702087654; NPV': 167276903.114719033241
Iter: 59, Guess: 11.98822702; NPV: -34315.879214172695; NPV': 173157248.228313893080
Iter: 60, Guess: 11.98842520; NPV: -34315.953126068991; NPV': 179137388.106261253357
Iter: 61, Guess: 11.98861676; NPV: -34316.024568817877; NPV': 185217295.240994751453
Iter: 62, Guess: 11.98880203; NPV: -34316.093664766166; NPV': 191396943.040042817593
Iter: 63, Guess: 11.98898133; NPV: -34316.160528277884; NPV': 197676305.780447095633
Iter: 64, Guess: 11.98915492; NPV: -34316.225266376721; NPV': 204055358.567246288061
Iter: 65, Guess: 11.98932310; NPV: -34316.287979327346; NPV': 210534077.293422698975
Iter: 66, Guess: 11.98948609; NPV: -34316.348761162386; NPV': 217112438.603331893682
Iter: 67, Guess: 11.98964415; NPV: -34316.407700160533; NPV': 223790419.857697159052
Iter: 68, Guess: 11.98979749; NPV: -34316.464879281302; NPV': 230567999.101392328739
Iter: 69, Guess: 11.98994633; NPV: -34316.520376560671; NPV': 237445155.032117486000
Iter: 70, Guess: 11.99009085; NPV: -34316.574265472373; NPV': 244421866.972285866737
Iter: 71, Guess: 11.99023125; NPV: -34316.626615256951; NPV': 251498114.841649025679
Iter: 72, Guess: 11.99036770; NPV: -34316.677491223447; NPV': 258673879.131316632032
Iter: 73, Guess: 11.99050036; NPV: -34316.726955025224; NPV': 265949140.880162149668
Iter: 74, Guess: 11.99062940; NPV: -34316.775064912632; NPV': 273323881.651466965675
Iter: 75, Guess: 11.99075495; NPV: -34316.821875965630; NPV': 280798083.511914968491
Iter: 76, Guess: 11.99087716; NPV: -34316.867440306734; NPV': 288371729.010823130608
Iter: 77, Guess: 11.99099616; NPV: -34316.911807297678; NPV': 296044801.160871148109
Iter: 78, Guess: 11.99111208; NPV: -34316.955023720024; NPV': 303817283.419962584972
Iter: 79, Guess: 11.99122503; NPV: -34316.997133942234; NPV': 311689159.673774063587
Iter: 80, Guess: 11.99133514; NPV: -34317.038180073352; NPV': 319660414.219356060028
Iter: 81, Guess: 11.99144249; NPV: -34317.078202105680; NPV': 327731031.749635219574
Iter: 82, Guess: 11.99154720; NPV: -34317.117238046259; NPV': 335900997.338365137577
Iter: 83, Guess: 11.99164937; NPV: -34317.155324038846; NPV': 344170296.426191449165
Iter: 84, Guess: 11.99174907; NPV: -34317.192494477029; NPV': 352538914.807125985622
Iter: 85, Guess: 11.99184642; NPV: -34317.228782109116; NPV': 361006838.615987539291
Iter: 86, Guess: 11.99194148; NPV: -34317.264218135555; NPV': 369574054.316117405891
Iter: 87, Guess: 11.99203433; NPV: -34317.298832299544; NPV': 378240548.687872469425
Iter: 88, Guess: 11.99212506; NPV: -34317.332652971367; NPV': 387006308.817352414131
Iter: 89, Guess: 11.99221374; NPV: -34317.365707226694; NPV': 395871322.086249053478
Iter: 90, Guess: 11.99230042; NPV: -34317.398020919987; NPV': 404835576.161223292351
Iter: 91, Guess: 11.99238519; NPV: -34317.429618752562; NPV': 413899058.985230386257
Iter: 92, Guess: 11.99246811; NPV: -34317.460524336369; NPV': 423061758.767428994179
Iter: 93, Guess: 11.99254922; NPV: -34317.490760253575; NPV': 432323663.974819481373
Iter: 94, Guess: 11.99262860; NPV: -34317.520348112041; NPV': 441684763.323866128922
Iter: 95, Guess: 11.99270630; NPV: -34317.549308597627; NPV': 451145045.772463977337
Iter: 96, Guess: 11.99278237; NPV: -34317.577661522722; NPV': 460704500.511960089207
Iter: 97, Guess: 11.99285686; NPV: -34317.605425872251; NPV': 470363116.960265457630
Iter: 98, Guess: 11.99292982; NPV: -34317.632619846154; NPV': 480120884.754399478436
Iter: 99, Guess: 11.99300129; NPV: -34317.659260899934; NPV': 489977793.744279444218
Iter: 100, Guess: 11.99307133; NPV: -34317.685365782243; NPV': 499933833.985330462456
Reached 100 iterations: switching to binary search algorithm ...
Looking for binary guesses
Binary search (eps = 1.0e-07):
------------------------------
Iter: 0 Rate[-0.0500000, 1.0000000]; NPV[12964.8581098 {} -13779.0539395]
Iter: 1 Rate[-0.0500000, 0.4750000]; NPV[12964.8581098 {} -5874.9766329]
Iter: 2 Rate[0.2125000, 0.4750000]; NPV[985.1496790 {} -5874.9766329]
Iter: 3 Rate[0.2125000, 0.3437500]; NPV[985.1496790 {} -2836.2213234]
Iter: 4 Rate[0.2125000, 0.2781250]; NPV[985.1496790 {} -1043.1593857]
Iter: 5 Rate[0.2125000, 0.2453125]; NPV[985.1496790 {} -61.5276866]
Iter: 6 Rate[0.2289062, 0.2453125]; NPV[453.2387213 {} -61.5276866]
Iter: 7 Rate[0.2371094, 0.2453125]; NPV[193.7702576 {} -61.5276866]
Iter: 8 Rate[0.2412109, 0.2453125]; NPV[65.6069580 {} -61.5276866]
Iter: 9 Rate[0.2432617, 0.2453125]; NPV[1.9119129 {} -61.5276866]
Iter: 10 Rate[0.2432617, 0.2442871]; NPV[1.9119129 {} -29.8397111]
Iter: 11 Rate[0.2432617, 0.2437744]; NPV[1.9119129 {} -13.9718684]
Iter: 12 Rate[0.2432617, 0.2435181]; NPV[1.9119129 {} -6.0319718]
Iter: 13 Rate[0.2432617, 0.2433899]; NPV[1.9119129 {} -2.0605282]
Iter: 14 Rate[0.2432617, 0.2433258]; NPV[1.9119129 {} -0.0744323]
Iter: 15 Rate[0.2432938, 0.2433258]; NPV[0.9187091 {} -0.0744323]
Iter: 16 Rate[0.2433098, 0.2433258]; NPV[0.4221306 {} -0.0744323]
Iter: 17 Rate[0.2433178, 0.2433258]; NPV[0.1738472 {} -0.0744323]
Iter: 18 Rate[0.2433218, 0.2433258]; NPV[0.0497069 {} -0.0744323]
Iter: 19 Rate[0.2433218, 0.2433238]; NPV[0.0497069 {} -0.0123628]
Iter: 20 Rate[0.2433228, 0.2433238]; NPV[0.0186720 {} -0.0123628]
Iter: 21 Rate[0.2433233, 0.2433238]; NPV[0.0031546 {} -0.0123628]
Iter: 22 Rate[0.2433233, 0.2433236]; NPV[0.0031546 {} -0.0046041]
Iter: 23 Rate[0.2433233, 0.2433234]; NPV[0.0031546 {} -0.0007248]
Iter: 24 Rate[0.2433234, 0.2433234]; NPV[0.0012149 {} -0.0007248]
Iter: 25 Rate[0.2433234, 0.2433234]; NPV[0.0002451 {} -0.0007248]
Iter: 26 Rate[0.2433234, 0.2433234]; NPV[0.0002451 {} -0.0002399]
Iter: 27 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0002399]
Iter: 28 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0001186]
Iter: 29 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0000580]
Iter: 30 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0000277]
Iter: 31 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0000125]
Iter: 32 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0000050]
Iter: 33 Rate[0.2433234, 0.2433234]; NPV[0.0000026 {} -0.0000012]
Iter: 34 Rate[0.2433234, 0.2433234]; NPV[0.0000007 {} -0.0000012]
Iter: 35 Rate[0.2433234, 0.2433234]; NPV[0.0000007 {} -0.0000002]
Iter: 36 Rate[0.2433234, 0.2433234]; NPV[0.0000002 {} -0.0000002]
NPV close enough to zero
------------------------------
=> 0.24332340405344438
:org_babel_ruby_eoe
```


<a id="org9a8c826"></a>

### Subsetting `CashFlow` with `#within(period)`

The `#within#` method allows you to get a `CashFlow` object that consists of only those `CashPoints` that fall within a given `Period`. The `fat_fin` gem includes `fat_period` which defines a `Period` class representing a range of dates. (See [FatPeriod gem github page](https://github.com/ddoherty03/fat_period)).

The `#within` method takes a `Period` parameter and returns a new `CashFlow` that contains only those `CashPoints` that fall within the given period. There is a twist, however: it adds a `CashPoint` dated the first date of the period that have a value equal to the `#value_on` that date of all `CashPoint~s that preceded the beginning of the given period. That way, all investment activity leading up to the given period is encapsulated in a single ~CashPoint` at the beginning of the period.

Recall that our `flow` example has the following ~CashPoint~s:

```
| Date       |     Amount |
|------------+------------|
| 2022-01-15 | -40,000.00 |
| 2022-02-15 |   2,000.00 |
| 2022-03-15 |   2,000.00 |
| 2022-04-15 |   2,000.00 |
| 2022-05-15 |   2,000.00 |
| 2022-06-15 |   2,000.00 |
| 2022-07-15 |   2,000.00 |
| 2022-08-15 |   2,000.00 |
| 2022-09-15 |   2,000.00 |
| 2022-10-15 |   2,000.00 |
| 2022-11-15 |   2,000.00 |
| 2022-12-15 |   2,000.00 |
| 2023-01-15 |   2,000.00 |
| 2023-02-15 |   2,000.00 |
| 2023-03-15 |   2,000.00 |
| 2023-04-15 |   2,000.00 |
| 2023-05-15 |   2,000.00 |
| 2023-06-15 |   2,000.00 |
| 2023-07-15 |  -3,000.00 |
| 2023-08-15 |   2,000.00 |
| 2023-09-15 |   2,000.00 |
| 2023-11-15 |  15,000.00 |
```

We can take subsets of if by passing the period of interest to `#within`. If we wanted to look at performance during the third quarter of 2022, for example, we could do this:

```ruby
q3 = Period.parse('2022-3Q')
flow3q = flow.within(q3)

# Format it all as a table
tab = [["Date", "Amount"], nil]
flow3q.cash_points.each do |cp|
  tab << [cp.date.iso, cp.amount.commas(2)]
end
tab
```

```
| Date       |     Amount |
|------------+------------|
| 2022-07-01 | -31,593.25 |
| 2022-07-15 |   2,000.00 |
| 2022-08-15 |   2,000.00 |
| 2022-09-15 |   2,000.00 |
```

It returns a new CashFlow that narrows this CashFlow to the given period. All CashPoints before the beginning of the period are rolled up into a single CashPoint having a date of the beginning of the period and an amount that represents their value\_on that date. All the CashPoints that fall within the period are retained and any CashPoints that are beyond the last date of the period are dropped.


<a id="org1662eed"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and the created tag, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="org38e2e2f"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/fat_fin>.


<a id="org211b5ee"></a>

# License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
