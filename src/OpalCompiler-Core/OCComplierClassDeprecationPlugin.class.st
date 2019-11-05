Class {
	#name : #OCComplierClassDeprecationPlugin,
	#superclass : #OCCompilerASTPlugin,
	#category : #'OpalCompiler-Core-Translator'
}

{ #category : #'class initialization' }
OCComplierClassDeprecationPlugin class >> initialize [
	self install
]

{ #category : #actions }
OCComplierClassDeprecationPlugin class >> install [
	<script>
	(CompilationContext defaultTransformationPlugins includes: self)
		ifTrue: [ ^ self ].
	CompilationContext addDefaultTransformationPlugin: self.
	self recompileTransformableDeprecatedClassReferences
]

{ #category : #private }
OCComplierClassDeprecationPlugin class >> priority [
	^ 3
]

{ #category : #'as yet unclassified' }
OCComplierClassDeprecationPlugin class >> recompileTransformableDeprecatedClassReferences [
	(self environment allBehaviors
		select: [ :e | 
			(e classSide includesSelector: #isDeprecated)
				and: [ e isDeprecated
						and: [ (e classSide compiledMethodAt: #isDeprecated)
								hasPragmaNamed: #transformTo: ] ] ])
		do: [ :e | (e classSide compiledMethodAt: #isDeprecated) recompile ]
]

{ #category : #actions }
OCComplierClassDeprecationPlugin class >> uninstall [
	<script>
	CompilationContext removeDefaultTransformationPlugin: self
]

{ #category : #testing }
OCComplierClassDeprecationPlugin >> hasTransformableDeprecatedClassReferences [
	^ ast allChildren
		anySatisfy: [ :e | 
			e isVariable
				and: [ e isGlobal
						and: [ e binding isGlobalClassNameBinding
								and: [ self isTransformableDeprecatedClass: e binding value ] ] ] ]
]

{ #category : #testing }
OCComplierClassDeprecationPlugin >> isTransformableDeprecatedClass: aClass [
	^ aClass isDeprecated
		and: [ (aClass classSide includesSelector: #isDeprecated)
				and: [ (aClass classSide compiledMethodAt: #isDeprecated)
						hasPragmaNamed: #transformTo: ] ]
]

{ #category : #'as yet unclassified' }
OCComplierClassDeprecationPlugin >> recompileMethodsReferencingMethodClass [
	| methodClass binding methods |
	methodClass := ast methodNode methodClass.
	binding := methodClass binding.
	methods := methodClass environment allBehaviors
		flatCollect: [ :e | e methods select: [ :f | f hasLiteral: binding ] ].
	Author
		useAuthor: 'AutoDeprecationRefactoring'
		during: [ methods do: #recompile ]
]

{ #category : #api }
OCComplierClassDeprecationPlugin >> shouldRecompileMethodsReferencingMethodClass [
	| methodNode |
	methodNode := ast methodNode.
	^ methodNode isNotNil
		and: [ methodNode selector = #isDeprecated
				and: [ methodNode methodClass isClassSide
						and: [ methodNode hasPragmaNamed: #transformTo: ] ] ]
]

{ #category : #api }
OCComplierClassDeprecationPlugin >> shouldTransformDeprecatedClassReferences [
	| methodNode |
	methodNode := ast methodNode.
	^ methodNode isNotNil
		and: [ methodNode selector isDoIt not
				and: [ self hasTransformableDeprecatedClassReferences ] ]
]

{ #category : #api }
OCComplierClassDeprecationPlugin >> transform [
	self shouldRecompileMethodsReferencingMethodClass
		ifTrue: [ self recompileMethodsReferencingMethodClass ].
	self shouldTransformDeprecatedClassReferences
		ifTrue: [ self transformTransformableDeprecatedClassReferences ].
	^ ast
]

{ #category : #'as yet unclassified' }
OCComplierClassDeprecationPlugin >> transformTransformableDeprecatedClassReferences [
	self transformableDeprecatedClassReferences
		do: [ :e | 
			| replacement rule |
			replacement := ((e classSide compiledMethodAt: #isDeprecated)
				pragmaNamed: #transformTo:) arguments first.
			rule := RBParseTreeRewriter new replace: e name with: replacement.
			rule executeTree: e ]
]

{ #category : #testing }
OCComplierClassDeprecationPlugin >> transformableDeprecatedClassReferences [
	^ ast allChildren
		select: [ :e | 
			e isVariable
				and: [ e isGlobal
						and: [ e binding isGlobalClassNameBinding
								and: [ self isTransformableDeprecatedClass: e binding value ] ] ] ]
]
