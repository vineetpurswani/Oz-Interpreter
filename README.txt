Group Members:	ayushman singh sisodiya 12188
		vineet purswani 12813
		deepak kumar 12228

Questions Attempted:

1:	NOP

2:	Variable creation [localvar ident(X) S]

3:	Variable-Variable binding [bind ident(X) ident(Y)]

4a:	Single Assignment Store with 
		variables bound to numerical values and record values

5a:	Variable-Value binding to numbers and records
 	AST:	[bind ident(x) v]
{	
	NOTE:	(a) 	If v is a record then its feature list should be a list of list
 			(b)		Features of a record is always a literal (not an identifier)	
 			(c)		Record label is a literal and not an identifier.
}

6:	If-then-else
	AST:	[conditional ident(x) s1 s2]

7:	Pattern Matching
	AST:	[match ident(x) p1 s1 s2]
{
	NOTE: p1 is always a record and matching of a literal with identifier is not allowed
}

4b, 5b: Procedures with closures
	AST:	[procedure [ident(x1) ... ident(xn)] s]	

8:	Procedure Application
	AST:	[apply ident(f) ident(x1) ... ident(xn)]

NOTE:
a)	# character  is not allowed in the AST
b) Some of the exceptions are handled using try-catch




Q2. Generate two threads 1. Of bits 0 and 1    2. Average of the first list
	To Run: Run as is in mozart. The runnable portion at end is commented

Q3. Lazy Append
	To Run: Run as is in mozart. Test case present.

Q4. Lazy QSort
	To Run: Run as is in mozart. Test case present

Q5. Threaded Hamming Problem
	To Run: Run as is in mozart. Test case present in code for 2,3,5

Q6. NSelect Message Passing
	To Run: Run as is in mozart. Test cases commented at the end portion. I've takes the
		end statements to be procedures and ran those procedures rather than running
		some statements.

Q7. Barriering using threads
	To Run: Run as is in mozart. Test cases commented at the end portion. Test
		case is self explanatory
