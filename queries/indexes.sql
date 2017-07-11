GenJoinT = Join (predicate = qualifier)
RelationT = TableAcces (alias = tableName)
ProjectT = Projection (indexesToProjectOn = attNames, xstreamTrick = source)
EqJoinT = Join (index1 and index2 = qualifier, xstreamTrick = leftSource and rightSource)
FilterT = Select (predicate = qualifier) 
	AND(#2="M",#7>50)
	AND(AND(#2="M",#7>50),#3="a") 
	OR(#2="M",AND(#7>50,#3="a"))
	
	#%d --> #2
	%s%s%s -> #7>30
	EQ_PATTERN = Pattern.compile("#(\\d+)=#(\\d+)");
	
	
select name || lastName from professor
SelectT (predicates = [#3&#1], xstreamTrick = [professor=Relation(A,B,C,D,E,F,G)])
select 3+2 from professor
SelectT