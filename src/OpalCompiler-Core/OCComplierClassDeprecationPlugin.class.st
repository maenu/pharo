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
	self isInstalled
		ifTrue: [ ^ self ].
	CompilationContext addDefaultTransformationPlugin: self.
	self recompileTransformableDeprecatedClassReferences
]

{ #category : #testing }
OCComplierClassDeprecationPlugin class >> isInstalled [
	^ CompilationContext defaultTransformationPlugins includes: self
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
	self isInstalled
		ifFalse: [ ^ self ].
	CompilationContext removeDefaultTransformationPlugin: self
]

{ #category : #testing }
OCComplierClassDeprecationPlugin >> hasTransformableDeprecatedClassReferences [
	^ ast methodNode isNotNil
		and: [ ast methodNode selector isDoIt not
				and: [ ast allChildren
						anySatisfy: [ :e | 
							e isVariable
								and: [ e isGlobal
										and: [ e binding isGlobalClassNameBinding
												and: [ self isTransformableDeprecatedClass: e binding value ] ] ] ] ] ]
]

{ #category : #testing }
OCComplierClassDeprecationPlugin >> isTransformableDeprecatedClass: aClass [
	^ aClass isDeprecated
		and: [ (aClass classSide includesSelector: #isDeprecated)
				and: [ (aClass classSide compiledMethodAt: #isDeprecated)
						hasPragmaNamed: #transformTo: ] ]
]

{ #category : #api }
OCComplierClassDeprecationPlugin >> isTransformableDeprecatedClassIsDeprecatedMethod [
	| methodNode |
	methodNode := ast methodNode.
	^ methodNode isNotNil
		and: [ methodNode selector = #isDeprecated
				and: [ methodNode methodClass isClassSide
						and: [ methodNode hasPragmaNamed: #transformTo: ] ] ]
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
OCComplierClassDeprecationPlugin >> transform [
	self isTransformableDeprecatedClassIsDeprecatedMethod
		ifTrue: [ self recompileMethodsReferencingMethodClass ].
	self hasTransformableDeprecatedClassReferences
		ifTrue: [ self transformTransformableDeprecatedClassReferences ].
	^ ast
]

{ #category : #'as yet unclassified' }
OCComplierClassDeprecationPlugin >> transformTransformableDeprecatedClassReferences [
	| changed |
	changed := false.
	self transformableDeprecatedClassReferences
		do: [ :e | 
			| replacement rule |
			replacement := ((e binding value classSide
				compiledMethodAt: #isDeprecated) pragmaAt: #transformTo:)
				arguments first.
			rule := RBParseTreeRewriter new replace: e name with: replacement.
			(rule executeTree: e)
				ifTrue: [ e replaceWith: rule tree.
					changed := true ] ].
	changed
		ifTrue:
			[ (ReparseAfterSourceEditing new newSource: ast formattedCode) signal ]
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
