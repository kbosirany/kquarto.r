# Format a table for a Quarto book

Renders a data frame as a styled, scrollable table in HTML output and as
a `booktabs` table in LaTeX/PDF output. It is meant to be called from
the chunks of the chapters of a book.

## Usage

``` r
kable(
  x,
  is_html_output = knitr::is_html_output() || interactive(),
  title = NULL,
  height = "100%"
)
```

## Arguments

- x:

  A data frame or a matrix.

- is_html_output:

  Whether the output is HTML. By default, detected with
  [`knitr::is_html_output()`](https://rdrr.io/pkg/knitr/man/output_type.html)
  (or `TRUE` in an interactive session).

- title:

  Optional caption of the table.

- height:

  Height of the scroll box in HTML output, e.g. `"300px"`.

## Value

A `knitr_kable` object.

## Details

In LaTeX output, only the first rows of `x` are kept (see
[`utils::head()`](https://rdrr.io/r/utils/head.html)), as a long table
does not fit in a page.

## Examples

``` r
kable(head(iris), is_html_output = TRUE, title = "Iris")
#> <div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:100%; overflow-x: scroll; width:100%; "><table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
#> <caption style="font-size: initial !important;">Iris</caption>
#>  <thead>
#>   <tr>
#>    <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Sepal.Length </th>
#>    <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Sepal.Width </th>
#>    <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Petal.Length </th>
#>    <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Petal.Width </th>
#>    <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> Species </th>
#>   </tr>
#>  </thead>
#> <tbody>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 5.1 </td>
#>    <td style="text-align:right;width: auto; "> 3.5 </td>
#>    <td style="text-align:right;width: auto; "> 1.4 </td>
#>    <td style="text-align:right;width: auto; "> 0.2 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 4.9 </td>
#>    <td style="text-align:right;width: auto; "> 3.0 </td>
#>    <td style="text-align:right;width: auto; "> 1.4 </td>
#>    <td style="text-align:right;width: auto; "> 0.2 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 4.7 </td>
#>    <td style="text-align:right;width: auto; "> 3.2 </td>
#>    <td style="text-align:right;width: auto; "> 1.3 </td>
#>    <td style="text-align:right;width: auto; "> 0.2 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 4.6 </td>
#>    <td style="text-align:right;width: auto; "> 3.1 </td>
#>    <td style="text-align:right;width: auto; "> 1.5 </td>
#>    <td style="text-align:right;width: auto; "> 0.2 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 5.0 </td>
#>    <td style="text-align:right;width: auto; "> 3.6 </td>
#>    <td style="text-align:right;width: auto; "> 1.4 </td>
#>    <td style="text-align:right;width: auto; "> 0.2 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#>   <tr>
#>    <td style="text-align:right;width: auto; "> 5.4 </td>
#>    <td style="text-align:right;width: auto; "> 3.9 </td>
#>    <td style="text-align:right;width: auto; "> 1.7 </td>
#>    <td style="text-align:right;width: auto; "> 0.4 </td>
#>    <td style="text-align:left;width: auto; "> setosa </td>
#>   </tr>
#> </tbody>
#> </table></div>
kable(head(iris), is_html_output = FALSE)
#> 
#> \begin{tabular}{rrrrl}
#> \toprule
#> Sepal.Length & Sepal.Width & Petal.Length & Petal.Width & Species\\
#> \midrule
#> 5.1 & 3.5 & 1.4 & 0.2 & setosa\\
#> 4.9 & 3.0 & 1.4 & 0.2 & setosa\\
#> 4.7 & 3.2 & 1.3 & 0.2 & setosa\\
#> 4.6 & 3.1 & 1.5 & 0.2 & setosa\\
#> 5.0 & 3.6 & 1.4 & 0.2 & setosa\\
#> \addlinespace
#> 5.4 & 3.9 & 1.7 & 0.4 & setosa\\
#> \bottomrule
#> \end{tabular}
```
