// -----------------------------------------
// Tests for "require" validation rule
// -----------------------------------------

module("Test require rule");

test("Required input", function(){
	ok($.valitron($("<p></p>"), "rule_required", {}, [], "some text").result, "There is some text")
});

test("Require on empty", function(){
	ok( ! $.valitron($("<p></p>"), "rule_required", {}, [], "").result, "Value: \"\"")
});

test("Require on null", function(){
	ok( ! $.valitron($("<p></p>"), "rule_required", {}, [], null).result, "Value: null")
});

test("Require on true", function(){
	ok( $.valitron($("<p></p>"), "rule_required", {}, [], true).result, "Value: true")
});

test("Require on false", function(){
	ok( ! $.valitron($("<p></p>"), "rule_required", {}, [], false).result, "Value: false")
});

test("Require on number", function(){
	ok( $.valitron($("<p></p>"), "rule_required", {}, [], 5545).result, "Value: 5545")
});