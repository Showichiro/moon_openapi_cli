///|
fn command() -> @argparse.Command {
  @argparse.Command(
    "apispec",
    about="Agent-friendly OpenAPI extraction CLI",
    version=VERSION,
    subcommand_required=true,
    subcommands=[
      @argparse.Command("endpoint", subcommand_required=true, subcommands=[
        @argparse.Command(
          "ls",
          about="List OpenAPI operations",
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("tag", about="Filter by tag"),
            @argparse.OptionArg("method", about="Filter by HTTP method"),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[
            @argparse.FlagArg("quiet", short='q'),
            @argparse.FlagArg("verbose"),
          ],
        ),
        @argparse.Command(
          "get",
          about="Extract one OpenAPI operation",
          positionals=[
            @argparse.PositionArg(
              "target",
              about="operationId, METHOD PATH, or PATH",
              num_args=@argparse.ValueRange(lower=1, upper=2),
              allow_hyphen_values=true,
            ),
          ],
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
            @argparse.OptionArg(
              "warnings",
              about="Warning output: text, json, or none",
              default_values=["text"],
            ),
          ],
          flags=[
            @argparse.FlagArg(
              "no-resolve",
              about="Skip reachable component inclusion and external ref import.",
            ),
            @argparse.FlagArg("verbose"),
          ],
        ),
        @argparse.Command(
          "search",
          about="Search OpenAPI operations",
          positionals=[
            @argparse.PositionArg(
              "query",
              about="Search query",
              num_args=@argparse.ValueRange(lower=1),
              allow_hyphen_values=true,
            ),
          ],
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("tag", about="Filter by tag"),
            @argparse.OptionArg("method", about="Filter by HTTP method"),
            @argparse.OptionArg("limit", about="Maximum results", default_values=[
              "10",
            ]),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[
            @argparse.FlagArg("quiet", short='q'),
            @argparse.FlagArg("verbose"),
          ],
        ),
      ]),
      @argparse.Command("schema", subcommand_required=true, subcommands=[
        @argparse.Command(
          "ls",
          about="List OpenAPI component schemas",
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[
            @argparse.FlagArg("quiet", short='q'),
            @argparse.FlagArg("verbose"),
          ],
        ),
        @argparse.Command(
          "get",
          about="Extract one OpenAPI component schema",
          positionals=[
            @argparse.PositionArg(
              "name",
              about="Schema name under components.schemas",
              num_args=@argparse.ValueRange::single(),
              allow_hyphen_values=true,
            ),
          ],
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
            @argparse.OptionArg(
              "warnings",
              about="Warning output: text, json, or none",
              default_values=["text"],
            ),
          ],
          flags=[@argparse.FlagArg("with-usages"), @argparse.FlagArg("verbose")],
        ),
        @argparse.Command(
          "search",
          about="Search OpenAPI component schemas",
          positionals=[
            @argparse.PositionArg(
              "query",
              about="Search query",
              num_args=@argparse.ValueRange(lower=1),
              allow_hyphen_values=true,
            ),
          ],
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("limit", about="Maximum results", default_values=[
              "10",
            ]),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[
            @argparse.FlagArg("quiet", short='q'),
            @argparse.FlagArg("verbose"),
          ],
        ),
      ]),
      @argparse.Command(
        "describe",
        about="Describe available apispec commands",
        options=[
          @argparse.OptionArg(
            "subcommand",
            about="Descriptor name such as endpoint.get",
          ),
        ],
      ),
      @argparse.Command("version", about="Print version"),
    ],
  )
}
