# Personal Finance Dashboard

An all-in-one R-Shiny dashboard to track and analyze the user's financial situation.


## Use Case \& Background

Carefully managing one's finances includes proper tracking, analysis, planning. As these things can be tedious or even overwhelming, the Personal Finance Dashboard provides an interface allowing its users to track their income, expenses, and asset purchases or sales. Furthermore, various charts provide a detailed analysis of the user's financial situation, and therefore, support the user in making adjustments to their financial habits.


## Technologies Used

- R: + Shiny, bslib, highcharter, and quantmod
- SQLite
- HTML
- CSS


## Implementation Details

### Data Storage/Export

To store all the necessary data, a SQLite database has been implemented.  
Upon starting the application, all the necessary tables are being created if they do not exist yet. For each asset, its price data is then being queried from Yahoo-Finance and stored in the *price\_data* table.  
The *income*, *expenses*, and *assets* tables are updated as soon as the user adds records using the dashboard's *Track* tab. Data can be added line-by-line using the UI or by uploading a .csv or .xlsx file, either appending the new data to the existing tables or completely overwriting them.  
Asset price data and currency exchange rates are being queried daily from Yahoo-Finance and are stored in the *price\_data* and *xrates* tables. Price data will only be queried for assets that are being owned by the user (i.e., he holds a quantity of $>0$). Currency exchange rates on the other hand are always being queried if the user made at least one transaction in a given currency or if the price of at least one asset he ever held is measured in that currency.  
The *settings* table enables the storage of user settings, such as whether the dark mode should be active or which date format should be used.  
Last, all income and expenses positions, as well as all asset transactions within the selected time frame can be exported to .csv files using using the download button found on the sidebar.  

### Data Processing

To keep on-memory storage to a minimum, only raw income-, expenses-, asset- and price data is stored in the database. Therefore, most of the various data processing tasks, such as typecasting, formatting, exchange rate conversions, and aggregations are repeated every time the underlying data changes (i.e., if the user tracks new information or if new price data is being queried) and when the user changes the selected time frame. For this reason, it is important to avoid any potential performance compromises resulting from extensive R usage. Most of these tasks are therefore being done using SQLite.

### Visualization
To visualize the user's financial situation, a combination of highcharter plots,  table-, and simple text outputs are displayed in the dashboard's various tabs.  
Data is aggregated on a monthly basis and each chart or metric was selected/designed with the intention of hitting the sweet spot between being as simple as possible, while at the same time providing just enough details to optimally support users in their financial decision-making.  
All of these components, as well as the dashboard itself, have been customized using the mechanism provided by R, as well as elements of HTML and CSS. Users can also switch between dark and light mode, and change the selected colors for profit and losses.  
In the *Settings* tab, the user can change various display settings, including chart colors, the date format, in which currency values should be displayed, and whether the dark mode should be enabled or not.  
Last, pop up messages indicate whether a user's action succeeded or if they tried to do something that cannot be done. Also, info-boxes are attached to most elements in the dashboard, which can be viewed by hovering over their title.  


## Demo Screenshots
<p align = "center">
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_1.png" width = "200" />
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_2.png" width = "200" />
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_3.png" width = "200" />
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_4.png" width = "200" />
  <br>
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_5.png" width = "200" />
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_6.png" width = "200" />
  <img src = "https://github.com/iamklager/personal_finance_dashboard/raw/main/.github/screenshot_7.png" width = "200" />
</p>

