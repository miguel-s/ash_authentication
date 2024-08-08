defmodule AshAuthentication.Dsl do
  @moduledoc false

  ###
  ### Only exists to move the DSL out of `AshAuthentication` to aid readability.
  ###

  import AshAuthentication.Utils, only: [to_sentence: 2]
  import Joken.Signer, only: [algorithms: 0]

  alias Ash.{Domain, Resource}

  @default_token_lifetime_days 14

  alias Spark.Dsl.Section

  @doc false
  @spec secret_type :: any
  def secret_type,
    do:
      {:or,
       [
         {:spark_function_behaviour, AshAuthentication.Secret,
          {AshAuthentication.SecretFunction, 2}},
         :string
       ]}

  @doc false
  @spec secret_doc :: String.t()
  def secret_doc,
    do:
      "Takes either a module which implements the `AshAuthentication.Secret` behaviour, a 2 arity anonymous function or a string."

  @doc false
  @spec dsl :: [Section.t()]
  def dsl do
    secret_type = secret_type()
    secret_doc = secret_doc()

    [
      %Section{
        name: :authentication,
        describe: "Configure authentication for this resource",
        no_depend_modules: [:domain],
        schema: [
          subject_name: [
            type: :atom,
            doc:
              "The subject name is used anywhere that a short version of your resource name is needed.  Must be unique system-wide and will be inferred from the resource name by default (ie `MyApp.Accounts.User` -> `user`)."
          ],
          domain: [
            type: {:behaviour, Domain},
            required: false,
            doc:
              "The name of the Ash domain to use to access this resource when doing anything authentication related."
          ],
          get_by_subject_action_name: [
            type: :atom,
            doc:
              "The name of the read action used to retrieve records. If the action doesn't exist, one will be generated for you.",
            default: :get_by_subject
          ],
          select_for_senders: [
            type: {:list, :atom},
            doc:
              "A list of fields that we will ensure are selected whenever a sender will be invoked.  Defaults to `[:email]` if there is an `:email` attribute on the resource, and `[]` otherwise."
          ]
        ],
        sections: [
          %Section{
            name: :tokens,
            describe: "Configure JWT settings for this resource",
            no_depend_modules: [:token_resource, :signing_secret],
            schema: [
              enabled?: [
                type: :boolean,
                doc: """
                Should JWTs be generated by this resource?
                """,
                default: false
              ],
              store_all_tokens?: [
                type: :boolean,
                doc:
                  "Store all tokens in the `token_resource`. See the [tokens guide](/documentation/topics/tokens.md) for more.",
                default: false
              ],
              require_token_presence_for_authentication?: [
                type: :boolean,
                doc:
                  "Require a locally-stored token for authentication. See the [tokens guide](/documentation/topics/tokens.md) for more.",
                default: false
              ],
              signing_algorithm: [
                type: :string,
                doc:
                  "The algorithm to use for token signing. Available signing algorithms are; #{to_sentence(algorithms(), final: "and")}.",
                default: hd(algorithms())
              ],
              token_lifetime: [
                type:
                  {:or,
                   [
                     :pos_integer,
                     {:tuple, [:pos_integer, {:in, [:days, :hours, :minutes, :seconds]}]}
                   ]},
                doc:
                  "How long a token should be valid. See [the tokens guide](/documentation/topics/tokens.md) for more.",
                default: {@default_token_lifetime_days, :days}
              ],
              token_resource: [
                type: {:or, [{:behaviour, Resource}, {:in, [false]}]},
                doc:
                  "The resource used to store token information, such as in-flight confirmations, revocations, and if `store_all_tokens?` is enabled, authentication tokens themselves.",
                required: true
              ],
              signing_secret: [
                type: secret_type,
                doc: "The secret used to sign tokens.  #{secret_doc}"
              ]
            ]
          },
          %Section{
            name: :strategies,
            describe: "Configure authentication strategies on this resource",
            entities: [],
            patchable?: true
          },
          %Section{
            name: :add_ons,
            describe: "Additional add-ons related to, but not providing authentication",
            entities: [],
            patchable?: true
          }
        ]
      }
    ]
  end
end
