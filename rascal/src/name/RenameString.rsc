module name::RenameString

import String;
import List;
import util::Maybe;
import name::Relation;
import name::Names;
import name::Gensym;
import name::HygienicCorrectness;
import name::Rename;

@doc{
This applies a (definition-)renaming to a string (represent as an lrel with origins). 
}
lrel[Maybe[loc], str] renameString(Edges refs, lrel[Maybe[loc], str] src, map[ID,str] subst) {
  src = for (<just(loc l), str x> <- src) {
    if ({l} in subst) {
      //println("Renaming <l>");
      append <just(l), subst[{l}]>;
    }
    else if ({l} in refs, def := refs[{l}], def in subst) {
      //println("Renaming definition <def>");
      append <just(l), subst[def]>;
    } 
    else {
      append <just(l), x>;
    }
  }
  return src;
}


lrel[Maybe[loc], str] fixHygieneString(NameGraph Gs, lrel[Maybe[loc], str] t, NameGraph(lrel[Maybe[loc], str]) resolveT) 
  = fixHygiene(Gs, t, renameString, resolveT); 

@doc{
This function maps (target language) name-IDs to (source or meta program) origins
through the reconstructed result origins.
}
NameGraph insertSourceNames(NameGraph targetGraph, lrel[loc, loc, str] reconOrgs, loc orgLoc) {
  return visit (targetGraph) {
    case loc l => sourceLoc
      when <l, loc sourceLoc, _> <- reconOrgs//, sourceLoc.path == orgLoc.path
  }
}


@doc{
An lrel coming from origins()) maps (source or meta program) origins to 
output string fragments. This functions reconstructs the source locations
of each chunk according to occurence in the output. 
}
lrel[loc, loc, str] reconstruct(lrel[Maybe[loc], str] orgs, loc src) {
  cur = |<src.scheme>://<src.authority><src.path>|(0, 0, <1, 0>, <1,0>);
 
  result = for (<org, str sub> <- orgs) {
    cur.length = size(sub);
    nls = size(findAll(sub, "\n"));
    cur.end.line += nls;
    if (nls != 0) {
      // reset
      cur.end.column = size(sub) - findLast(sub, "\n") - 1;
    }
    else {
      cur.end.column += size(sub);
    }
    if (just(loc l) := org) {
      append <cur, l, sub>;
    }
    else {
      throw "No origin: \'<sub>\'";
    }
    cur.offset += size(sub);
    cur.begin.column = cur.end.column;
    cur.begin.line = cur.end.line;
  }
  
  return result;
}
