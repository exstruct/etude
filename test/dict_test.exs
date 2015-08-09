defmodule Etude.Node.Dict.Test do
  use EtudeTestHelper

  etudetest "should lazily get a property on a dict", [
    render: [
      %Assign{
        name: :user,
        expression: %Call{
          module: :lazy,
          function: :user,
          arguments: ["1"]
        }
      },
      %{
        id: %Dict{
          function: :get,
          arguments: [
            %Var{name: :user},
            :id
          ],
        },
        name: %Dict{
          function: :get,
          arguments: [
            %Var{name: :user},
            :name
          ],
        },
        email: %Dict{
          function: :get,
          arguments: [
            %Var{name: :user},
            :email
          ],
        },
        friends: %Comprehension{
          collection: %Dict{
            function: :get,
            arguments: [
              %Var{name: :user},
              :friends
            ]
          },
          value: %Assign{
            name: :friend
          },
          expression: %Dict{
            function: :get,
            arguments: [
              %Var{name: :friend},
              :name
            ]
          }
        }
      }
    ]
  ], %{id: "1", name: "Robert", email: "robert@example.com", friends: ["Joe", "Mike"]}

end
