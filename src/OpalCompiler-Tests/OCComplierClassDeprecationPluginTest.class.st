Class {
	#name : #OCComplierClassDeprecationPluginTest,
	#superclass : #TestCase,
	#instVars : [
		'systemAdditions',
		'wasInstalled'
	],
	#category : #'OpalCompiler-Tests-Translator'
}

{ #category : #adding }
OCComplierClassDeprecationPluginTest >> addClassNamed: aSymbol [
	| class |
	class := Object
		subclass: aSymbol
		instanceVariableNames: ''
		classVariableNames: ''
		package: self class category.
	systemAdditions push: class.
	^ class
]

{ #category : #adding }
OCComplierClassDeprecationPluginTest >> deprecateClass: aClass [
	aClass classSide
		compile:
			'isDeprecated
	^ true'
]

{ #category : #adding }
OCComplierClassDeprecationPluginTest >> deprecateClass: aClass transformTo: aString [
	aClass classSide
		compile:
			'isDeprecated
	<transformTo: ''' , aString
				,
					'''>
	^ true'
]

{ #category : #adding }
OCComplierClassDeprecationPluginTest >> deprecateNotClass: aClass [
	aClass classSide
		compile:
			'isDeprecated
	^ false'
]

{ #category : #running }
OCComplierClassDeprecationPluginTest >> setUp [
	super setUp.
	systemAdditions := Stack new.
	wasInstalled := OCComplierClassDeprecationPlugin isInstalled
]

{ #category : #running }
OCComplierClassDeprecationPluginTest >> tearDown [
	super tearDown.
	wasInstalled
		ifFalse: [ OCComplierClassDeprecationPlugin uninstall ].
	[ systemAdditions isEmpty ]
		whileFalse: [ systemAdditions pop removeFromSystem ]
]

{ #category : #tests }
OCComplierClassDeprecationPluginTest >> testFirstInstallPluginThenDeprecateWithTransformToClassThenCompileReferencing [
	| replacement deprecated referencing |
	OCComplierClassDeprecationPlugin install.
	replacement := self addClassNamed: #OCForTestReplacement.
	deprecated := self addClassNamed: #OCForTestDeprecated.
	self deprecateClass: deprecated transformTo: replacement name.
	referencing := self addClassNamed: #OCForTestReferencing.
	referencing
		compile:
			'references
	^ {OCForTestDeprecated . 1 . self class . OCForTestDeprecated . OCForTestReferencing}'.
	self
		assert: (referencing compiledMethodAt: #references) sourceCode
		equals:
			'references
	^ {OCForTestReplacement.
	1.
	self class.
	OCForTestReplacement.
	OCForTestReferencing}'.
	self
		assert: referencing new references
		equals:
			{replacement.
			1.
			referencing.
			replacement.
			referencing}
]
