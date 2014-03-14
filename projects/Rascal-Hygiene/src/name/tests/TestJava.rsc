module name::tests::TestJava

import lang::missgrant::base::Compile;
import lang::missgrant::base::AST;
import lang::missgrant::base::Implode;
import lang::missgrant::base::NameRel;
import lang::java::NameRel;
import lang::java::jdt::m3::Core;

import name::tests::TestString;
import name::NameGraph;
import name::NameFixString;
import name::IDs;
import name::Gensym;
import name::HygienicCorrectness;
import util::Maybe;
import IO;
import String;
import List;

/*
 * NOTE: create an empty java project generated-missgrant in your Eclipse workspace.
 * (This is needed (as of now) to get name analysis from JDT.)
 */

str output = "generated-missgrant";
str missGrantClass = "MissGrant";


str compile1java() = compile(missGrantClass, statemachine1());

void compile1javaToDisk() {
  writeFile(|project://<output>/src/<missGrantClass>.java|, compile1java());
}

NameGraph javaNames1() = m3toNameGraph(createM3FromEclipseProject(|project://<output>|));


Controller illCompiled1java() = 
  lang::missgrant::base::Implode::load(|project://Rascal-Hygiene/input/doors1-java-ill.ctl|);

str compileIllCompiled1java() = compile(missGrantClass, illCompiled1java());

void compileIllCompiled1javaToDisk() {
  writeFile(|project://<output>/src/<missGrantClass>.java|, compileIllCompiled1java());
}

NameGraph illCompiled1Names() = resolveNames(illCompiled1java());

NameGraph illCompiled1javaNames() {
  return m3toNameGraph(createM3FromEclipseProject(|project://<output>|));
}

NameGraph reconNames() = 
   insertSourceNames(illCompiled1javaNames(), 
     reconstruct(origins(compileIllCompiled1java()),
         |project://<output>/src/<missGrantClass>.java|), 
         |project://Rascal-Hygiene/input/illcompiledjava.ctl|); 

NameGraph resolveJava(lrel[Maybe[loc], str] src) {
  // Ugh, make this nice..
  writeFile(|project://<output>/src/<missGrantClass>.java|, ("" | it + x | x <- src<1> ));
  return insertSourceNames(m3toNameGraph(createM3FromEclipseProject(|project://<output>|)), 
     reconstruct(src,
         |project://<output>/src/<missGrantClass>.java|), 
         |project://Rascal-Hygiene/input/illcompiledjava.ctl|);
}

lrel[Maybe[loc], str] fixIllCompiledJava1() { 
  compileIllCompiled1javaToDisk(); // start clean;
  outFile = |project://<output>/src/<missGrantClass>.java|;
  orgs = nameFixString(illCompiled1Names(), origins(compileIllCompiled1java()), resolveJava, outFile);
  newSource = ( "" | it + x | x <- orgs<1> );
  writeFile(outFile, newSource);
  return orgs;
}

test bool testIllCompiled1() {
  newSource = fixIllCompiledJava1();
  return isCompiledHygienically(illCompiled1Names(), resolveJava(newSource));
}

void compileIllCompiled1javaToDisk() {
  writeFile(|project://<output>/src/<missGrantClass>.java|, compileIllCompiled1java());
}

