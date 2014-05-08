%-*- mode: Latex; abbrev-mode: true; auto-fill-function: do-auto-fill -*-

%include lhs2TeX.fmt
%include myFormat.fmt

\out{
\begin{code}
-- This code was automatically generated by lhs2tex --code, from the file 
-- HSoM/LSystems.lhs.  (See HSoM/MakeCode.bat.)

\end{code}
}

\chapter[L-Systems and Generative Grammars]
{Musical L-Systems and Generative Grammars}
\label{ch:lsystems}

\begin{code}
module Euterpea.Examples.LSystems where

import Euterpea
import Data.List hiding (transpose)
import System.Random 
\end{code} 

\section{Generative Grammars}
\label{sec:grammars}

A \emph{grammar} describes a \emph{formal language}.  One can either
design a \emph{recognizer} (or \emph{parser}) for that language, or
design a \emph{generator} that generates sentences in that language.
We are interested in using grammars to generate music, and thus we are
only interested in generative grammars.

A generative grammar is a four-tuple $(N,T,n,P)$, where:
\begin{itemize}
\item $N$ is the set of \emph{non-terminal symbols}.
\item $T$ is the set of \emph{terminal symbols}.
\item $n$ is the \emph{initial symbol}.
\item $P$ is a set of \emph{production rules}, where each production
  rule is a pair $(X,Y)$, often written $X \rightarrow Y$.  $X$ and
  $Y$ are sentences (or \emph{sentential forms}) formed over the
  alphabet $N \cup T$, and $X$ contains at least one non-terminal.
\end{itemize}

A \emph{Lindenmayer system}, or \emph{L-system}, is an example of a
generative grammer, but is different in two ways:
\begin{enumerate}
\item The \emph{sequence} of sentences is as important as the
  individual sentences, and
\item A new sentence is generated from the previous one by applying as
  many productions as possible on each step---a kind of ``parallel
  production.''
\end{enumerate}

Lindenmayer was a biologist and mathematician, and he used L-systems
to describe the growth of certain biological organisms (such as
plants, and in particular algae).

We will limit our discussion  to L-systems that have the following
additional characteristics:
\begin{enumerate}
\item They are \emph{context-free}: the left-hand side of each
  production (i.e.\ $X$ above) is a single non-terminal.
\item No distinction is made between terminals and non-terminals (with
  no loss of expressive power---why?).
\end{enumerate}

We will consider both \emph{deterministic} and \emph{non-deterministic}
grammars.  A deterministic grammar has exactly one production
corresponding to each non-terminal symbol in the alphabet, whereas a
non-deterministic grammar may have more than one, and thus we will
need some way to choose between them.

\subsection{A Simple Implementation}

A framework for simple, context-free, deterministic grammars can be
designed in Haskell as follows.  We represent the set of productions
as a list of symbol/list-of-symbol pairs:
\begin{code}

data DetGrammar a = DetGrammar  a           -- start symbol
                                [(a,[a])]   -- productions
  deriving Show
\end{code}
To generate a succession of ``sentential forms,'' we need to define a
function that, given a grammar, returns a list of lists of symbols:
\begin{code}
detGenerate :: Eq a => DetGrammar a -> [[a]]
detGenerate (DetGrammar st ps) = iterate (concatMap f) [st]
            where f a = maybe [a] id (lookup a ps)
\end{code}

\syn{|maybe| is a convenient function for conditionally giving a
  result based on the structure of a value of type |Maybe a|.  It is
  defined in the Standard Prelude as:
\begin{spec}
maybe                 :: b -> (a -> b) -> Maybe a -> b
maybe _  f  (Just x)  = f x
maybe z  _  Nothing   = z
\end{spec}

|lookup :: Eq a => a -> [(a,b)] -> Maybe b| is a convenient function
for finding the value associated with a given key in an association
list.  For example:
\begin{spec}
lookup 'b' [('a',0),('b',1),('c',2)]  ==> Just 1
lookup 'd' [('a',0),('b',1),('c',2)]  ==> Nothing
\end{spec}
}
%% |lookup| is defined in the Standard Prelude as:
%% \begin{spec}
%% lookup                  :: (Eq a) => a -> [(a,b)] -> Maybe b
%% lookup  _ []            =  Nothing
%% lookup  key ((x,y):xys)
%%     | key == x          =  Just y
%%     | otherwise         =  lookup key xys
%% \end{spec}

Note that we expand each symbol ``in parallel'' at each step, using
|concatMap|.  The repetition of this process at each step is achieved
using |iterate|.  Note also that a list of productions is essentially
an \emph{association list}, and thus the |Data.List| library function
|lookup| works quite well in finding the production rule that we seek.
Finally, note once again how the use of higher-order functions makes
this definition concise yet efficient.

As an example of the use of this simple program, a Lindenmayer grammer
for red algae (taken from \cite{}) is given by:
\begin{code}
redAlgae = DetGrammar 'a'
               [  ('a',"b|c"),   ('b',"b"),  ('c',"b|d"),
                  ('d',"e\\d"),  ('e',"f"),  ('f',"g"),
                  ('g',"h(a)"),  ('h',"h"),  ('|',"|"),
                  ('(',"("),     (')',")"),  ('/',"\\"),
                  ('\\',"/")
               ]
\end{code}
%% a -> bc
%% c -> bd
%% d -> e\d
%% e -> f
%% f -> g
%% g -> h(a)
%% \ -> /
%% / -> \

\syn{Recall that |'\\'| is how the backslash character is written in
  Haskell, because a single backslash is the ``escape'' character for
  writing special characters such as newline (|'\n'|), tab (|'\t'|),
  and so on.  Since the backslash is used in this way, it also is a
  special character, and must be escaped using itself, i.e.\ |'\\'|. }

Then |detGenerate redAlgae| gives us the result that we want---or, to
make it look nicer, we could do:
\begin{code}
t n g = sequence_ (map putStrLn (take n (detGenerate g)))
\end{code}
For example, |t 10 redAlgae| yields:
\begin{verbatim}
a
b|c
b|b|d
b|b|e\d
b|b|f/e\d
b|b|g\f/e\d
b|b|h(a)/g\f/e\d
b|b|h(b|c)\h(a)/g\f/e\d
b|b|h(b|b|d)/h(b|c)\h(a)/g\f/e\d
b|b|h(b|b|e\d)\h(b|b|d)/h(b|c)\h(a)/g\f/e\d
\end{verbatim}

\todo{Include a graphical rendering of the red algae.}

\vspace{.1in}\hrule

\begin{exercise}{\em
Define a function |strToMusic :: AbsPitch -> Dur -> String -> Music
Pitch| that interprets the strings generated by |redAlgae| as music.
Specifically, |strToMusic ap d str| interprets the string |str| in the
following way:
\begin{enumerate}
\item
Characters |'a'| through |'h'| are interpreted as notes, each with
duration |d| and absolute pitches |ap|, |ap+2|, |ap+4|, |ap+5|,
|ap+7|, |ap+9|, |ap+11|, and |ap+12|, respectively (i.e.\ a major
scale).
\item
|'||'| is interpreted as a no-op.
\item
|'/'| and |'\\'| are both interpreted as a rest of length |d|.
\item
|'('| is interpreted as a transposition by 5 semitones (a perfect fourth).
\item
|')'| is interpreted as a transposition by -5 semitones.
\end{enumerate} }
\end{exercise}

\begin{exercise}{\em Design a function |testDet :: Grammar a -> Bool|
    such that |testDet g| is |True| if |g| has exactly one rule for
    each of its symbols; i.e.\ it is deterministic.  Then modify the
    |generate| function above so that it returns an error if a grammer
    not satisfying this constraint is given as argument.}
\end{exercise}

\vspace{.1in}\hrule

\subsection{A More General Implementation}

The design given in the last section only captures deterministic
context-free grammars, and the generator considers only parallel
productions that are charactersitic of L-Systems.

We would also like to consider non-deterministic grammars, where a
user can specify the probability that a particular rule is selected,
as well as possibly non-context free (i.e.\ context sensitive)
grammars.  Thus we will represent a generative grammar a bit more
abstractly, as a data structure that has a starting sentence in an
(implicit, polymorphic) alphabet, and a list of production rules:
\begin{code}
data Grammar a = Grammar  a          -- start sentence
                          (Rules a)  -- production rules
     deriving Show
\end{code}
The production rules are instructions for converting sentences in the
alphabet to other sentences in the alphabet.  A rule set is either a
set of uniformly distributed rules (meaning that those with the same
left-hand side have an equal probability of being chosen), or a set of
stochastic rules (each of which is paired with a probabilty).  A
specific rule consists of a left-hand side and a right-hand side.
\begin{code}
data Rules a  =  Uni  [Rule a] 
              |  Sto  [(Rule a, Prob)]
     deriving (Eq, Ord, Show)

data Rule a = Rule { lhs :: a, rhs :: a }
     deriving (Eq, Ord, Show)

type Prob = Double
\end{code}

One of the key sub-problems that we will have to solve is how to
probabilistically select a rule from a set of rules, and use that rule
to expand a non-terminal.  We define the following type to capture
this process:
\begin{code}
type ReplFun a  = [[(Rule a, Prob)]] -> (a, [Rand]) -> (a, [Rand])
type Rand       = Double
\end{code}
The idea here is that a function |f :: ReplFun a| is such that |f rules
(s,rands)| will return a new sentence |s'| in which each symbol in |s|
has been replaced according to some rule in |rules| (which are grouped
by common left-hand side).  Each rule is chosen probabilitically based
on the random numbers in |rands|, and thus the result also includes a
new list of random numbers to account for those ``consumed'' by the
replacement process.

With such a function in hand, we can now define a function that, given
a grammar, generates an infinite list of the sentences produced by
this replacement process.  Because the process is non-deterministic,
we also pass a seed (an integer) to generate the initial pseudo-random
number sequence to give us repeatable results.
\begin{code}
gen :: Ord a => ReplFun a -> Grammar a -> Int -> [a]
gen f (Grammar s rules) seed = 
    let  Sto newRules  = toStoRules rules
         rands         = randomRs (0.0,1.0) (mkStdGen seed)
    in  if checkProbs newRules
        then generate f newRules (s,rands)
        else (error "Stochastic rule-set is malformed.")
\end{code}

|toStoRules| converts a list of uniformly distributed rules to an
equivalent list of stochastic rules.  Each set of uniform rules with
the same LHS is converted to a set of stochastic rules in which the
probability of each rule is one divided by the number of uniform
rules.

\begin{code}
toStoRules :: (Ord a, Eq a) => Rules a -> Rules a  
toStoRules (Sto rs)  = Sto rs
toStoRules (Uni rs)  = 
  let rs' = groupBy (\r1 r2 -> lhs r1 == lhs r2) (sort rs)
  in Sto (concatMap insertProb rs')

insertProb :: [a] -> [(a, Prob)] 
insertProb rules =  let prb = 1.0 / fromIntegral (length rules)
	       	    in zip rules (repeat prb)
\end{code}

\syn{|groupBy :: (a->a->Bool) -> [a] -> [[a]]| is a |Data.List|
  library function that behaves as follows: |groupBy eqfn xs| returns
  a list of lists such that all elements in each sublist are ``equal''
  in the sense defined by |eqfn|.}

|checkProbs| takes a list of production rules and checks whether, for
every rule with the same LHS, the probabilities sum to one (plus or
minus some epsilon, currenty set to |0.001|).
\begin{code}
checkProbs :: (Ord a, Eq a) => [(Rule a, Prob)] -> Bool
checkProbs rs = and (map checkSum (groupBy sameLHS (sort rs)))

eps = 0.001 

checkSum :: [(Rule a, Prob)] -> Bool 
checkSum rules =  let mySum = sum (map snd rules)
                  in abs (1.0 - mySum) <= eps 

sameLHS :: Eq a => (Rule a, Prob) -> (Rule a, Prob) -> Bool 
sameLHS (r1,f1) (r2,f2) = lhs r1 == lhs r2
\end{code}

|generate| takes a replacement function, a list of rules, a starting
sentence, and a source of random numbers.  It returns an infinite list
of sentences.
\begin{code}
generate ::  Eq a =>  
             ReplFun a -> [(Rule a, Prob)] -> (a,[Rand]) -> [a] 
generate f rules xs = 
  let  newRules      =  map probDist (groupBy sameLHS rules)
       probDist rrs  =  let (rs,ps) = unzip rrs
                        in zip rs (tail (scanl (+) 0 ps))
  in map fst (iterate (f newRules) xs)
\end{code}

A key aspect of the |generate| algorithm above is to compute the
\emph{probability density} of each successive rule, which is
basically the sum of its probability plus the probabilities of all
rules that precede it.

\section{An L-System Grammar for Music}
\label{sec:musical-lsystem}

The previous section gave a generative framework for a generic
grammar.  For a musical L-system we will define a specific grammar,
whose sentences are defined as follows.  A musical L-system sentence
is either:
\begin{itemize}
\item A non-terminal symbol |N a|.
\item A sequential composition |s1 :+ s2|.
\item A functional composition |s1 :. s2|. 
\item The symbol |Id|, which will eventually be interpeted as the
  identity function.
\end{itemize}
We capture this in the |LSys| data type:
\begin{code}
data LSys a  =  N a 
             |  LSys a   :+   LSys a 
             |  LSys a   :.   LSys a 
             |  Id 
     deriving (Eq, Ord, Show) 
\end{code}
The idea here is that sentences generated from this grammar are
relative to a starting note, and thus the above constructions will be
interpreted as functions that take that starting note as an argument.
This will all become clear shortly, but first we need to define a
replacement function for this grammar.  

We will treat |(:+)| and |(:.)| as binary branches, and recursively
traverse each of their arguments.  We will treat |Id| as a constant that
never gets replaced.  Most importantly, each non-terminal of the form
|N x| could each be the left-hand side of a rule, so we call the
function |getNewRHS| to generate the replacement term for it.

\begin{code}
replFun :: Eq a => ReplFun (LSys a)
replFun rules (s, rands) =
  case s of
    a :+ b  ->  let  (a',rands')   = replFun rules (a, rands )
                     (b',rands'')  = replFun rules (b, rands')
                in (a' :+ b', rands'')
    a :. b  ->  let  (a',rands')   = replFun rules (a, rands )
                     (b',rands'')  = replFun rules (b, rands')
                in (a' :. b', rands'')
    Id      ->  (Id, rands)
    N x     ->  (getNewRHS rules (N x) (head rands), tail rands)
\end{code}

%% Note the use of |filter| to select only the rules whose left-hand
%% side matches the non-terminal.

|getNewRHS| is defined as:
\begin{code}
getNewRHS :: Eq a => [[(Rule a, Prob)]] -> a -> Rand -> a
getNewRHS rrs ls rand = 
  let  loop ((r,p):rs)  = if rand <= p then rhs r else loop rs
       loop []          = error "getNewRHS anomaly"
  in case (find (\ ((r,p):_) -> lhs r == ls) rrs) of
        Just rs  -> loop rs
        Nothing  -> error "No rule match"
\end{code}

\syn{|find :: (a->Bool) -> [a] -> Maybe a| is another |Data.List|
  function that returns the first element of a list that satisfies a
  predicate, or |Nothing| if there is no such element.}

\subsection{Examples}

The final step is to interpret the resulting sentence (i.e.\ a value
of type |LSys a|) as music.  As mentioned earlier, the intent of the
|LSys| design is that a value is interpreted as a \emph{function} that
is applied to a single note (or, more generally, a single |Music|
value).  The specific constructors are interpreted as follows:
\begin{code}
type IR a b = [(a, Music b -> Music b)]  -- ``interpetation rules'' 

interpret :: (Eq a) => LSys a -> IR a b -> Music b -> Music b
interpret (a :. b)  r m = interpret a r (interpret b r m)  
interpret (a :+ b)  r m = interpret a r m :+: interpret b r m
interpret Id        r m = m 
interpret (N x)     r m = case (lookup x r) of
                            Just f   -> f m
                            Nothing  -> error "No interpetation rule"
\end{code}

For example, we could define the following interpretation rules:
\begin{code}
data LFun = Inc | Dec | Same
     deriving (Eq, Ord, Show)

ir :: IR LFun Pitch
ir = [ (Inc, transpose 1),
       (Dec, transpose (-1)),
       (Same, id)]

inc, dec, same :: LSys LFun
inc   = N Inc
dec   = N Dec
same  = N Same
\end{code}
In other words, |inc| transposes the music up by one semitone, |dec|
transposes it down by a semitone, and |same| does nothing.

Now let's build an actual grammar.  |sc| increments a note followed by
its decrement---the two notes are one whole tone apart:
\begin{code}
sc = inc :+ dec
\end{code}

Now let's define a bunch of rules as follows:
\begin{code}
r1a  = Rule inc (sc :. sc)
r1b  = Rule inc sc
r2a  = Rule dec (sc :. sc)
r2b  = Rule dec sc
r3a  = Rule same inc
r3b  = Rule same dec
r3c  = Rule same same
\end{code}
and the corresponding grammar:
\begin{code}
g1 = Grammar same (Uni [r1b, r1a, r2b, r2a, r3a, r3b])
\end{code}

Finally, we generate a sentence at some particular level, and
interpret it as music:
\begin{code}
t1 n =  instrument Vibraphone $
        interpret (gen replFun g1 42 !! n) ir (c 5 tn)
\end{code}
\out{$ }
Try ``|play (t1 3)|'' or ``|play (t1 4)|'' to hear the result.

\vspace{.1in}\hrule

\begin{exercise}{\em 
Play with the L-System grammar defined above.  Change the production
rules.  Add probabilities to the rules, i.e.\ change it into a |Sto|
grammar.  Change the random number seed.  Change the depth of
recursion.  And also try changing the ``musical seed'' (i.e.\ the note
|c 5 tn|).}
\end{exercise}

\begin{exercise}{\em
Define a new L-System structure.  In particular, (a) define a new
version of |LSys| (for example, add a parallel constructor) and its
associated interpretation, and/or (b) define a new version of |LFun|
(perhaps add something to control the volume) and its associated
interpretation.  Then define some grammars with the new design to
generate interesting music.}
\end{exercise}

\vspace{.1in}\hrule


