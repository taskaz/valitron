// -----------------------------------------
// Tests for "require" validation rule
// -----------------------------------------

module("Max validation");
test("Max number 'max:10'", function(){
	ok( ! $.valitron($("<p></p>"), "rule_max", {}, [10], 5545).result, "Value: 5545")
});

test("Max number 'max:10'", function(){
	ok( $.valitron($("<p></p>"), "rule_max", {}, [10], 5).result, "Value: 5")
});

test("Max on string 'max:10'", function(){
	ok( ! $.valitron($("<p></p>"), "rule_max", {}, [10], "this should fail for shure").result, "Value: this should fail for shure")
});

test("Max on string 'max:10'", function(){
	ok( $.valitron($("<p></p>"), "rule_max", {}, [10], "valid").result, "Value: valid")
});

test("Max on bool 'max:1'", function(){
	ok( $.valitron($("<p></p>"), "rule_max", {}, [1], true).result, "Value: true")
});