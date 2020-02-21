# rpn-calculator
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](../LICENSE-APACHE)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE-MIT)

This project is a calculator that can parse both RPN and infix expressions. 
It uses the shunting yard algorithm to transpile infix expressions into RPN expressions.
Then, it uses a stack machine to get the result of the RPN expression.

## Getting Started
These are the steps to quickly deploy this app.

### Prerequisites

The programming language used for this project is [Crystal](https://crystal-lang.org), which means an Linux environment is needed in order to compile the code.
[Readline](https://tiswww.case.edu/php/chet/readline/rltop.html) and [PCRE](https://www.pcre.org/) have to be installed to the Linux environment as well in order to compile the code.
### Installing

Refer to the [Development](#development) section for more information.
Binary releases will be added in the future to the GitHub repo.

## Usage

TODO: Write usage instructions here
So far, only REPL is supported for the calculator. Support for command-line arguments is planned.

## Development

After checking out the repo, run `shards install` to install the necessary dependencies. Then, run `crystal spec` to run the tests.

```bash
git clone https://github.com/Afront/Project-Pebbles.git
cd Project-Pebbles/rpn-calculator
shards install
crystal build
./bin/crystal
```

## Contributing

1. Fork it (<https://github.com/your-github-user/rpn-calculator/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE-APACHE)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE-MIT)

This project is dual-licensed under Apache 2.0 and the MIT license.

