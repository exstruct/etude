defmodule ExprTest.Partial do
  use ExUnit.Case
  use ExprTestHelper

  exprtest "should call a partial", [
    render: [
      %Partial{
        function: :user
      }
    ],
    user: [
      %{"name" => "Robert"}
    ]
  ], %{"name" => "Robert"}

  exprtest "should call a partial with a different scope", [
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

end