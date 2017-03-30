module refactor::forloop::NeededVariables

import lang::java::\syntax::Java18;
import ParseTree;
import IO;
import refactor::forloop::ProspectiveOperation;
import MethodVar;
import Set;
import refactor::forloop::OperationType;
import String;

public set[str] retrieveNeededVariables(ProspectiveOperation prOp) {
	set[str] neededVariables = {};
	
	if (prOp.operation == REDUCE)
		return {};
	else if (isLocalVariableDeclarationStatement(prOp.stmt))
		neededVariables += retrieveNeededVarsFromLocalVariableDeclarationStmt(prOp.stmt);		
 	else
		neededVariables += retrieveNeededVarsFromStatement(prOp.stmt);
	
	return neededVariables;
}

// XXX Parsing twice (isLocal... and this method) the stmt
// should not be a big deal since it's only a stmt from a prospective operation.
// Using this pattern (parsing to check if a stmt is of the type #Something) and then parsing again
// could refactor in the future to return a Tuple, with the bool and the parsed tree.
private set[str] retrieveNeededVarsFromLocalVariableDeclarationStmt(str stmt) {
	set[str] neededVariables = {};
	
	lvdlStmt = parse(#LocalVariableDeclarationStatement, stmt);
	
	visit(lvdlStmt) {
		case (VariableDeclaratorId) `<Identifier id>`: neededVariables += unparse(id);
		
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: neededVariables += unparse(id);
			}
		}	
	}
	
	return neededVariables;
}

private set[str] retrieveNeededVarsFromStatement(str stmt) {
	set[str] neededVariables = {};

	stmt = parse(#Statement, getCorrectStatementAsString(stmt));
	
	visit (stmt) {
		case LocalVariableDeclaration lvdl: {
			visit(lvdl) {
				case (VariableDeclaratorId) `<Identifier id>`: neededVariables += unparse(id);
			}
		}
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: neededVariables += unparse(id);
			}
		}
	}
	
	return neededVariables;
}

private str getCorrectStatementAsString(str stmt) {
	// stmt does not end with ';' it can't be parsed as a statement
	// it can also be a block
	if(!(endsWith(stmt, ";") || endsWith(stmt, "}")))
		return stmt + ";";
	return stmt;
}