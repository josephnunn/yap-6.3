
:- category(class_hierarchy,
	implements(class_hierarchyp)).


	:- info([
		version is 1.0,
		author is 'Paulo Moura',
		date is 2000/7/24,
		comment is 'Class hierarchy predicates.']).


	class(Class) :-
		self(Self),
		instantiates_class(Self, Class).


	classes(Classes) :-
		self(Self),
		findall(Class, instantiates_class(Self, Class), Classes).


	ancestor(Ancestor) :-
		self(Self),
		ancestor(Self, Ancestor).


	ancestor(Self, Ancestor) :-
		instantiates_class(Self, Ancestor).

	ancestor(Self, Ancestor) :-
		instantiates_class(Self, Class),
		superclass(Class, Ancestor).
  

	ancestors(Ancestors) :-
		self(Self),
		findall(Ancestor, ancestor(Self, Ancestor), Ancestors).


	instance(Instance) :-
		self(Self),
		instantiates_class(Instance, Self).


	instances(Instances) :-
		self(Self),
		findall(Instance, instantiates_class(Instance, Self), Instances).


	subclass(Subclass) :-
		self(Self),
		specializes_class(Subclass, Self).


	subclasses(Subclasses) :-
		self(Self),
		findall(Subclass, specializes_class(Subclass, Self), Subclasses).


	superclass(Superclass) :-
		self(Self),
		superclass(Self, Superclass).

	superclass(Self, Superclass) :-
		specializes_class(Self, Superclass).

	superclass(Self, Superclass) :-
		specializes_class(Self, Class),
		superclass(Class, Superclass).

	superclasses(Superclasses) :-
		self(Self),
		findall(Superclass, specializes_class(Self, Superclass), Superclasses).


	leaf(Leaf) :-
		self(Self),
		leaf(Self, Leaf).


	leaf(Self, Leaf) :-
		instantiates_class(Leaf, Self),
		\+ instantiates_class(_, Leaf),
		\+ specializes_class(_, Leaf).

	leaf(Self, Leaf) :-
		specializes_class(Leaf, Self),
		\+ instantiates_class(_, Leaf),
		\+ specializes_class(_, Leaf).

	leaf(Self, Leaf) :-
		specializes_class(Subclass, Self),
		leaf(Subclass, Leaf).


	leaves(Leaves) :-
		self(Self),
		findall(Leaf, leaf(Self, Leaf), Leaves).


	leaf_instance(Leaf) :-
		self(Self),
  		leaf_instance(Self, Leaf).


  	leaf_instance(Self, Leaf) :-
  		instantiates_class(Leaf, Self),
  		\+ instantiates_class(_, Leaf).

  	leaf_instance(Self, Leaf) :-
  		specializes_class(Subclass, Self),
		leaf_instance(Subclass, Leaf).


	leaf_instances(Leaves) :-
		self(Self),
		findall(Leaf, leaf_instance(Self, Leaf), Leaves).


	leaf_class(Leaf) :-
		self(Self),
  		leaf_class(Self, Leaf).
  		
  	leaf_class(Self, Leaf) :-
  		specializes_class(Leaf, Self),
  		\+ specializes_class(_, Leaf).

  	leaf_class(Self, Leaf) :-
  		specializes_class(Subclass, Self),
		leaf_class(Subclass, Leaf).

	leaf_classes(Leaves) :-
		self(Self),
		findall(Leaf, leaf_class(Self, Leaf), Leaves).


	descendant(Descendant) :-
		self(Self),
		descendant(Self, Descendant).


	descendant(Self, Descendant) :-
		instantiates_class(Descendant, Self).

	descendant(Self, Descendant) :-
		specializes_class(Descendant, Self),
		\+ instantiates_class(Descendant, Self).

	descendant(Self, Descendant) :-
		specializes_class(Subclass, Self),
		descendant(Subclass, Descendant).


	descendants(Descendants) :-
		self(Self),
		findall(Descendant, descendant(Self, Descendant), Descendants).


	descendant_class(Descendant) :-
		self(Self),
		descendant_class(Self, Descendant).
		

	descendant_class(Self, Descendant) :-
		specializes_class(Descendant, Self).

	descendant_class(Self, Descendant) :-
		specializes_class(Subclass, Self),
		descendant_class(Subclass, Descendant).


	descendant_classes(Descendants) :-
		self(Self),
		findall(Descendant, descendant_class(Self, Descendant), Descendants).


	descendant_instance(Descendant) :-
		self(Self),
		descendant_instance(Self, Descendant).
		

	descendant_instance(Self, Descendant) :-
		instantiates_class(Descendant, Self).

	descendant_instance(Self, Descendant) :-
		specializes_class(Subclass, Self),
		descendant_instance(Subclass, Descendant).


	descendant_instances(Descendants) :-
		self(Self),
		findall(Descendant, descendant_instance(Self, Descendant), Descendants).


:- end_category.
