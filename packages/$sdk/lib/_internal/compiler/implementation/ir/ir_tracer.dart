library dart2js.ir_tracer;

import 'dart:async' show EventSink;

import 'ir_nodes.dart' as ir;
import 'ir_nodes.dart' hide Function;
import '../tracer.dart';

/**
 * If true, show LetCont expressions in output.
 */
const bool IR_TRACE_LET_CONT = false;

class IRTracer extends TracerUtil implements Visitor {
  int indent = 0;
  EventSink<String> output;

  IRTracer(this.output);

  void traceGraph(String name, ir.Function graph) {
    tag("cfg", () {
      printProperty("name", name);
      visitFunction(graph);
    });
  }

  // Temporary field used during tree walk
  Names names;

  visitFunction(ir.Function f) {
    names = new Names();
    BlockCollector builder = new BlockCollector(names);
    f.accept(builder);

    printNode(builder.entry);
    for (Block block in builder.cont2block.values) {
      printNode(block);
    }
    names = null;
  }

  printNode(Block block) {
    tag("block", () {
      printProperty("name", block.name);
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      printProperty("predecessors", block.pred.map((n) => n.name));
      printProperty("successors", block.succ.map((n) => n.name));
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
          // We could print parameters here,
          // but does the hydra tool actually use this info??
        });
      });
      tag("HIR", () {
        block.body.accept(this);
      });
    });
  }

  void printStmt(String resultVar, String contents) {
    int bci = 0;
    int uses = 0;
    addIndent();
    add("$bci $uses $resultVar $contents <|@\n");
  }

  visitLetPrim(LetPrim node) {
    String id = names.name(node.primitive);
    printStmt(id, "LetPrim $id = ${formatPrimitive(node.primitive)}");
    node.body.accept(this);
  }

  visitLetCont(LetCont node) {
    if (IR_TRACE_LET_CONT) {
      String dummy = names.name(node);
      String id = names.name(node.continuation);
      printStmt(dummy, "LetCont $id = <$id>");
    }
    node.body.accept(this);
  }

  visitInvokeStatic(InvokeStatic node) {
    String dummy = names.name(node);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "InvokeStatic $callName ($args) $kont");
  }

  visitInvokeContinuation(InvokeContinuation node) {
    String dummy = names.name(node);
    String kont = formatReference(node.continuation);
    String arg = formatReference(node.argument);
    printStmt(dummy, "InvokeContinuation $kont ($arg)");
  }

  String formatReference(Reference ref) {
    Definition target = ref.definition;
    if (target is Continuation && target.body == null) {
      return "return"; // Do not generate a name for the return continuation
    } else {
      return names.name(ref.definition);
    }
  }

  String formatPrimitive(Primitive p) {
    return p.accept(this);
  }

  visitConstant(ir.Constant node) {
    return "Constant ${node.value}";
  }

  visitParameter(Parameter node) {
    return "Parameter ${names.name(node)}";
  }

  visitContinuation(Continuation node) {
    return "Continuation ${names.name(node)}";
  }

  visitExpression(Expression e) {}
  visitPrimitive(Primitive p) {}
  visitDefinition(Definition d) {}
  visitNode(Node n) {}
}

/** 
 * Invents (and remembers) names for Continuations, Parameters, etc.
 * The names must match the conventions used by IR Hydra, e.g. 
 * Continuations and Functions must have names of form B### since they
 * are visualized as basic blocks.
 */
class Names {
  final Map<Object, String> names = {};
  final Map<String, int> counters = {
    'r': 0,
    'B': 0,
    'v': 0,
    'x': 0
  };

  String prefix(x) {
    if (x is Parameter) return 'r';
    if (x is Continuation || x is ir.Function) return 'B';
    if (x is Primitive) return 'v';
    return 'x';
  }

  String name(x) {
    String nam = names[x];
    if (nam == null) {
      String pref = prefix(x);
      int id = counters[pref]++;
      nam = names[x] = '${pref}${id}';
    }
    return nam;
  }
}

/**
 * A vertex in the graph visualization, used in place of basic blocks.  
 */
class Block {
  String name;
  final List<Parameter> parameters;
  final Expression body;
  final List<Block> succ = <Block>[];
  final List<Block> pred = <Block>[];

  Block(this.name, this.parameters, this.body);

  void addEdgeTo(Block successor) {
    succ.add(successor);
    successor.pred.add(this);
  }
}

class BlockCollector implements Visitor {
  Block entry;
  final Map<Continuation, Block> cont2block = <Continuation, Block> {};
  Block current_block;

  Names names;
  BlockCollector(this.names);

  Block getBlock(Continuation c) {
    Block block = cont2block[c];
    if (block == null) {
      block = new Block(names.name(c), [c.parameter], c.body);
      cont2block[c] = block;
    }
    return block;
  }

  visitFunction(ir.Function f) {
    entry = current_block = new Block(names.name(f), [], f.body);
    f.body.accept(this);
  }
  visitLetPrim(LetPrim exp) {
    exp.body.accept(this);
  }
  visitLetCont(LetCont exp) {
    exp.continuation.accept(this);
    exp.body.accept(this);
  }
  visitInvokeStatic(InvokeStatic exp) {
    Definition target = exp.continuation.definition;
    if (target is Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitInvokeContinuation(InvokeContinuation exp) {
    Definition target = exp.continuation.definition;
    if (target is Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }
  visitConstant(ir.Constant constant) {}
  visitParameter(Parameter p) {}
  visitContinuation(Continuation c) {
    var old_node = current_block;
    current_block = getBlock(c);
    c.body.accept(this);
    current_block = old_node;
  }

  visitPrimitive(Primitive p) {}
  visitDefinition(Definition d) {}
  visitExpression(Expression e) {}
  visitNode(Node n) {}
}
