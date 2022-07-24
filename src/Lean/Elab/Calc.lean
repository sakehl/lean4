/-
Copyright (c) 2022 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
import Lean.Elab.App

namespace Lean.Elab.Term
open Meta

/--
  Decompose `e` into `(r, a, b)`.

  Remark: it assumes the last two arguments are explicit. -/
private def relation? (e : Expr) : MetaM (Option (Expr × Expr × Expr)) :=
  if e.getAppNumArgs < 2 then
    return none
  else
    return some (e.appFn!.appFn!, e.appFn!.appArg!, e.appArg!)

/--
  Elaborate `calc`-steps
-/
def elabCalcSteps (steps : Array Syntax) : TermElabM Expr := do
  let mut proofs := #[]
  let mut types  := #[]
  for step in steps do
    let type  ← elabType step[0]
    let some (_, lhs, _) ← relation? type |
      throwErrorAt step[0] "invalid 'calc' step, relation expected{indentExpr type}"
    if types.size > 0 then
      let some (_, _, prevRhs) ← relation? types.back | unreachable!
      unless (← isDefEqGuarded lhs prevRhs) do
        throwErrorAt step[0] "invalid 'calc' step, left-hand-side is {indentD m!"{lhs} : {← inferType lhs}"}\nprevious right-hand-side is{indentD m!"{prevRhs} : {← inferType prevRhs}"}"
    types := types.push type
    let proof ← elabTermEnsuringType step[2] type
    synthesizeSyntheticMVars
    proofs := proofs.push proof
  let mut result := proofs[0]!
  let mut resultType := types[0]!
  for i in [1:proofs.size] do
    let some (r, a, b) ← relation? resultType | unreachable!
    let some (s, _, c) ← relation? (← instantiateMVars types[i]!) | unreachable!
    let (α, β, γ)       := (← inferType a, ← inferType b, ← inferType c)
    let (u_1, u_2, u_3) := (← getLevel α, ← getLevel β, ← getLevel γ)
    let t ← mkFreshExprMVar (← mkArrow α (← mkArrow γ (mkSort levelZero)))
    let selfType := mkAppN (Lean.mkConst ``Trans [u_1, u_2, u_3]) #[α, β, γ, r, s, t]
    match (← trySynthInstance selfType) with
    | LOption.some self =>
      result := mkAppN (Lean.mkConst ``Trans.trans [u_1, u_2, u_3]) #[α, β, γ, r, s, t, self, a, b, c, result, proofs[i]!]
      resultType := (← instantiateMVars (← inferType result)).headBeta
      unless (← relation? resultType).isSome do
        throwErrorAt steps[i]! "invalid 'calc' step, step result is not a relation{indentExpr resultType}"
    | _ => throwErrorAt steps[i]! "invalid 'calc' step, failed to synthesize `Trans` instance{indentExpr selfType}"
    pure ()
  return result

/-- Step-wise reasoning over transitive relations.
```
calc
  a = b := pab
  b = c := pbc
  ...
  y = z := pyz
```
proves `a = z` from the given step-wise proofs. `=` can be replaced with any
relation implementing the typeclass `Trans`. Instead of repeating the right-
hand sides, subsequent left-hand sides can be replaced with `_`. -/
@[builtinTermElab «calc»]
def elabCalc : TermElab :=  fun stx expectedType? => do
  let steps := #[stx[1]] ++ stx[2].getArgs
  let result ← elabCalcSteps steps
  ensureHasType expectedType? result
