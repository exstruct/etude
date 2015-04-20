defmodule EtudeTest.Partial do
  use EtudeTestHelper

  etudetest "should call a partial", [
    render: [
      %Partial{
        function: :user
      }
    ],
    user: [
      %{"name" => "Robert"}
    ]
  ], %{"name" => "Robert"}

  etudetest "should call a partial with a different scope", [
    render: [
      %Assign{name: :foo, expression: "Parent"},
      {
        %Var{name: :foo},
        %Partial{function: :partial1}
      }
    ],
    partial1: [
      %Assign{name: :foo, expression: "Child 1"},
      {
        %Var{name: :foo},
        %Partial{function: :partial2}
      }
    ],
    partial2: [
      %Assign{name: :foo, expression: "Child 2"},
      %Var{name: :foo}
    ]
  ], {"Parent", {"Child 1", "Child 2"}}

  etudetest "should render a partial inside a comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4],
        expression: %Partial{function: :partial}
      }
    ],
    partial: [
      "HI!"
    ]
  ], ["HI!", "HI!", "HI!", "HI!"]

end