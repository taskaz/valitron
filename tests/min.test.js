// -----------------------------------------
// Tests for "require" validation rule
// -----------------------------------------

module("Min validation");
test("Min number 'min:10'", function(){
	ok( $.valitron($("<p></p>"), "rule_min", {}, [10], 5545).result, "Value: 5545")
});

test("Min number 'min:10'", function(){
	ok( ! $.valitron($("<p></p>"), "rule_min", {}, [10], 5).result, "Value: 5")
});

test("Min on string 'min:10'", function(){
	ok( $.valitron($("<p></p>"), "rule_min", {}, [10], "this should pass for shure").result, "Value: this should pass for shure")
});

test("Min on string 'min:10'", function(){
	ok( ! $.valitron($("<p></p>"), "rule_min", {}, [10], "invalid").result, "Value: invalid")
});

test("Min on bool 'min:1'", function(){
	ok( $.valitron($("<p></p>"), "rule_min", {}, [1], true).result, "Value: true")
});