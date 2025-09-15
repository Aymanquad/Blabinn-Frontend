# Linting Rules for Chatify

This document outlines the comprehensive linting rules and automated code quality checks for the Chatify Flutter application.

## Overview

The linting system consists of:
- **Static Analysis**: Dart analyzer with custom rules
- **Code Formatting**: Automatic code formatting
- **Pre-commit Hooks**: Automated checks before commits
- **CI/CD Integration**: Automated checks in pull requests
- **Custom Rules**: Chatify-specific quality checks

## Static Analysis Rules

### Error Rules (Must Fix)
- `always_declare_return_types`: Always declare return types
- `always_put_control_body_on_new_line`: Put control body on new line
- `always_put_required_named_parameters_first`: Required parameters first
- `always_require_non_null_named_parameters`: Require non-null parameters
- `avoid_print`: Never use print statements
- `avoid_dynamic_calls`: Avoid dynamic calls
- `avoid_catches_without_on_clauses`: Specify exception types
- `avoid_classes_with_only_static_members`: Avoid static-only classes
- `avoid_function_literals_in_foreach_calls`: Use proper iteration
- `avoid_implementing_value_types`: Don't implement value types
- `avoid_null_checks_in_equality_operators`: Use proper equality
- `avoid_positional_boolean_parameters`: Use named boolean parameters
- `avoid_private_typedef_functions`: Don't use private typedefs
- `avoid_redundant_argument_values`: Remove redundant arguments
- `avoid_return_types_on_setters`: Don't return types on setters
- `avoid_returning_null`: Don't return null
- `avoid_setters_without_getters`: Provide getters with setters
- `avoid_shadowing_type_parameters`: Don't shadow type parameters
- `avoid_single_cascade_in_expression_statements`: Use proper cascades
- `avoid_slow_async_io`: Avoid slow async I/O
- `avoid_type_to_string`: Don't convert types to strings
- `avoid_types_as_parameter_names`: Don't use types as parameter names
- `avoid_types_on_closure_parameters`: Don't type closure parameters
- `avoid_unnecessary_containers`: Remove unnecessary containers
- `avoid_unused_constructor_parameters`: Remove unused parameters
- `avoid_void_async`: Don't use void async
- `await_only_futures`: Only await futures
- `cancel_subscriptions`: Cancel subscriptions
- `close_sinks`: Close sinks
- `control_flow_in_finally`: Don't use control flow in finally
- `deprecated_consistency`: Use deprecated consistently
- `empty_catches`: Don't have empty catch blocks
- `empty_constructor_bodies`: Don't have empty constructors
- `empty_statements`: Don't have empty statements
- `exhaustive_cases`: Handle all cases
- `hash_and_equals`: Implement hash and equals
- `implementation_imports`: Don't import implementations
- `invariant_booleans`: Don't use invariant booleans
- `iterable_contains_unrelated_type`: Check related types
- `join_return_with_assignment`: Join return with assignment
- `library_private_types_in_public_api`: Don't expose private types
- `no_duplicate_case_values`: Don't duplicate case values
- `no_logic_in_create_state`: Don't put logic in createState
- `noop_primitive_operations`: Don't do no-op operations
- `null_check_on_nullable_type_parameter`: Check nullable types
- `null_closures`: Don't use null closures
- `one_member_abstracts`: Don't have single-member abstracts
- `only_throw_errors`: Only throw errors
- `overridden_fields`: Don't override fields
- `package_names`: Use proper package names
- `package_prefixed_library_names`: Use package prefixes
- `parameter_assignments`: Don't assign to parameters
- `prefer_asserts_in_initializer_lists`: Use asserts in initializers
- `prefer_asserts_with_message`: Use asserts with messages
- `prefer_collection_literals`: Use collection literals
- `prefer_conditional_assignment`: Use conditional assignment
- `prefer_const_constructors`: Use const constructors
- `prefer_const_constructors_in_immutables`: Use const in immutables
- `prefer_const_declarations`: Use const declarations
- `prefer_const_literals_to_create_immutables`: Use const literals
- `prefer_constructors_over_static_methods`: Use constructors
- `prefer_contains`: Use contains
- `prefer_expression_function_bodies`: Use expression bodies
- `prefer_final_fields`: Use final fields
- `prefer_final_in_for_each`: Use final in for-each
- `prefer_final_locals`: Use final locals
- `prefer_for_elements_to_map_fromIterable`: Use for-elements
- `prefer_function_declarations_over_variables`: Use function declarations
- `prefer_generic_function_type_aliases`: Use generic function types
- `prefer_if_elements_to_conditional_expressions`: Use if-elements
- `prefer_if_null_operators`: Use if-null operators
- `prefer_initializing_formals`: Use initializing formals
- `prefer_inlined_adds`: Use inlined adds
- `prefer_int_literals`: Use int literals
- `prefer_interpolation_to_compose_strings`: Use interpolation
- `prefer_is_empty`: Use isEmpty
- `prefer_is_not_empty`: Use isNotEmpty
- `prefer_is_not_operator`: Use is not operator
- `prefer_iterable_whereType`: Use whereType
- `prefer_null_aware_operators`: Use null-aware operators
- `prefer_relative_imports`: Use relative imports
- `prefer_single_quotes`: Use single quotes
- `prefer_spread_collections`: Use spread collections
- `prefer_typing_uninitialized_variables`: Type uninitialized variables
- `provide_deprecation_message`: Provide deprecation messages
- `public_member_api_docs`: Document public APIs
- `recursive_getters`: Don't use recursive getters
- `require_trailing_commas`: Require trailing commas
- `sized_box_for_whitespace`: Use SizedBox for whitespace
- `slash_for_doc_comments`: Use /// for doc comments
- `sort_child_properties_last`: Sort child properties last
- `sort_constructors_first`: Sort constructors first
- `sort_unnamed_constructors_first`: Sort unnamed constructors first
- `test_types_in_equals`: Test types in equals
- `throw_in_finally`: Don't throw in finally
- `tighten_type_of_initializing_formals`: Tighten initializing formals
- `type_annotate_public_apis`: Type annotate public APIs
- `type_init_formals`: Type init formals
- `unawaited_futures`: Don't leave futures unawaited
- `unnecessary_await_in_return`: Don't await in return
- `unnecessary_brace_in_string_interps`: Remove unnecessary braces
- `unnecessary_const`: Remove unnecessary const
- `unnecessary_constructor_name`: Remove unnecessary constructor names
- `unnecessary_getters_setters`: Remove unnecessary getters/setters
- `unnecessary_lambdas`: Remove unnecessary lambdas
- `unnecessary_late`: Remove unnecessary late
- `unnecessary_new`: Remove unnecessary new
- `unnecessary_null_aware_assignments`: Remove unnecessary null-aware
- `unnecessary_null_checks`: Remove unnecessary null checks
- `unnecessary_null_in_if_null_operators`: Remove unnecessary null
- `unnecessary_nullable_for_final_variable_declarations`: Remove unnecessary nullable
- `unnecessary_overrides`: Remove unnecessary overrides
- `unnecessary_parenthesis`: Remove unnecessary parentheses
- `unnecessary_raw_strings`: Remove unnecessary raw strings
- `unnecessary_statements`: Remove unnecessary statements
- `unnecessary_string_escapes`: Remove unnecessary escapes
- `unnecessary_string_interpolations`: Remove unnecessary interpolations
- `unnecessary_this`: Remove unnecessary this
- `unrelated_type_equality_checks`: Check related types
- `unsafe_html`: Don't use unsafe HTML
- `use_build_context_synchronously`: Use BuildContext synchronously
- `use_colored_box`: Use ColoredBox
- `use_decorated_box`: Use DecoratedBox
- `use_enums`: Use enums
- `use_full_hex_values_for_flutter_colors`: Use full hex values
- `use_function_type_syntax_for_parameters`: Use function type syntax
- `use_if_null_to_convert_nulls_to_bools`: Use if-null for bools
- `use_is_even_rather_than_modulo`: Use isEven
- `use_key_in_widget_constructors`: Use keys in constructors
- `use_late_for_private_fields_and_variables`: Use late for private
- `use_named_constants`: Use named constants
- `use_raw_strings`: Use raw strings
- `use_rethrow_when_possible`: Use rethrow
- `use_setters_to_change_properties`: Use setters
- `use_string_buffers`: Use StringBuffer
- `use_super_parameters`: Use super parameters
- `use_test_throws_matchers`: Use test throws matchers
- `use_to_and_as_if_applicable`: Use to and as
- `valid_regexps`: Use valid regexps
- `void_checks`: Use void checks

## Custom Rules

### Chatify-Specific Rules
- `prefer_try_catch`: Use try-catch for error handling
- `prefer_logger_over_print`: Use Logger instead of print
- `prefer_state_selectors`: Use state selectors for performance
- `prefer_optimized_images`: Use OptimizedImage widgets
- `require_analytics_tracking`: Add analytics for user actions
- `require_public_api_docs`: Document public APIs
- `prefer_error_boundaries`: Use ErrorBoundary widgets
- `prefer_repaint_boundary`: Use RepaintBoundary for expensive widgets
- `prefer_null_aware_operators`: Use null-aware operators
- `prefer_async_await`: Use async/await over .then()

## Pre-commit Hooks

### Automated Checks
1. **Dart Format**: Automatic code formatting
2. **Dart Analyze**: Static analysis
3. **Flutter Test**: Run tests
4. **Import Organization**: Check import order
5. **Naming Conventions**: Check naming standards
6. **Error Handling**: Check error handling patterns
7. **Performance**: Check performance best practices
8. **Documentation**: Check documentation coverage

### Custom Hooks
- **Check Imports**: Verify import organization
- **Check Naming**: Verify naming conventions
- **Check Error Handling**: Verify error handling
- **Check Performance**: Verify performance practices
- **Check Documentation**: Verify documentation

## CI/CD Integration

### GitHub Actions Workflow
- **Static Analysis**: Flutter analyze
- **Testing**: Unit and integration tests
- **Security**: Vulnerability scanning
- **Performance**: Performance testing
- **Quality**: Code quality metrics
- **Build**: Build verification
- **Dependencies**: Dependency checking
- **Documentation**: Documentation generation

### Quality Gates
- All tests must pass
- No security vulnerabilities
- Performance benchmarks met
- Code coverage thresholds
- Documentation coverage
- Build success

## Usage

### Local Development
```bash
# Install pre-commit hooks
pre-commit install

# Run all checks
pre-commit run --all-files

# Run specific check
pre-commit run dart-format
```

### CI/CD
```bash
# Run Flutter analyze
flutter analyze --fatal-infos

# Run tests
flutter test --coverage

# Check formatting
flutter format --set-exit-if-changed .
```

## Configuration Files

- `analysis_options.yaml`: Static analysis rules
- `.pre-commit-config.yaml`: Pre-commit hooks
- `.github/workflows/code_review.yml`: CI/CD workflow
- `CODE_REVIEW_STANDARDS.md`: Review standards
- `LINTING_RULES.md`: This documentation

## Best Practices

1. **Run checks locally** before committing
2. **Fix all errors** before submitting PR
3. **Address warnings** when possible
4. **Follow naming conventions** consistently
5. **Document public APIs** thoroughly
6. **Use proper error handling** patterns
7. **Optimize for performance** proactively
8. **Maintain test coverage** above 80%
9. **Keep dependencies updated** regularly
10. **Review security** considerations

This comprehensive linting system ensures consistent, high-quality code across the Chatify application while maintaining security, performance, and maintainability standards.
