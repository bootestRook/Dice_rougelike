#include "native_dice_throw_solver.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <array>
#include <chrono>
#include <limits>

using namespace godot;

void NativeDiceThrowSolver::_bind_methods() {
	ClassDB::bind_method(D_METHOD("solve_throw", "count", "targets", "options"), &NativeDiceThrowSolver::solve_throw, DEFVAL(Dictionary()));
}

NativeDiceThrowSolver::NativeDiceThrowSolver() {
	auto seed = static_cast<uint32_t>(std::chrono::high_resolution_clock::now().time_since_epoch().count());
	rng.seed(seed);
}

Dictionary NativeDiceThrowSolver::solve_throw(int32_t p_count, const Array &p_targets, const Dictionary &p_options) {
	const auto start = std::chrono::high_resolution_clock::now();
	int count = CLAMP(static_cast<int>(p_count), 1, MAX_DICE);
	if (p_options.has("seed")) {
		rng.seed(static_cast<uint32_t>(static_cast<int64_t>(p_options["seed"])));
	}

	Array plans;
	Array predicted_values;
	std::vector<ThrowParams> selected_params;
	bool has_explicit_target = false;
	for (int i = 0; i < count; i++) {
		if (i < p_targets.size() && sanitize_target(p_targets[i]) != 0) {
			has_explicit_target = true;
			break;
		}
	}
	for (int i = 0; i < count; i++) {
		int target_value = 0;
		if (i < p_targets.size()) {
			target_value = sanitize_target(p_targets[i]);
		}
		if (target_value == 0 && has_explicit_target) {
			target_value = random_pip();
		}
		ThrowParams params = solve_single(i, count, target_value, p_options, selected_params);
		selected_params.push_back(params);
		plans.append(params_to_dictionary(params));
		predicted_values.append(params.predicted_value);
	}

	const auto end = std::chrono::high_resolution_clock::now();
	const int64_t latency_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();

	Dictionary result;
	result["ok"] = true;
	result["plans"] = plans;
	result["predicted_values"] = predicted_values;
	result["latency_ms"] = latency_ms;
	result["source"] = String("native_fast_solver");
	return result;
}

int NativeDiceThrowSolver::sanitize_target(const Variant &p_value) const {
	if (p_value.get_type() == Variant::NIL) {
		return 0;
	}
	int value = static_cast<int>(static_cast<int64_t>(p_value));
	return value >= 1 && value <= 6 ? value : 0;
}

int NativeDiceThrowSolver::random_pip() {
	std::uniform_int_distribution<int> dist(1, 6);
	return dist(rng);
}

real_t NativeDiceThrowSolver::randf(real_t p_min, real_t p_max) {
	std::uniform_real_distribution<double> dist(static_cast<double>(p_min), static_cast<double>(p_max));
	return static_cast<real_t>(dist(rng));
}

Vector3 NativeDiceThrowSolver::face_normal(int p_value) const {
	switch (p_value) {
		case 1:
			return Vector3(0, 1, 0);
		case 6:
			return Vector3(0, -1, 0);
		case 2:
			return Vector3(0, 0, 1);
		case 5:
			return Vector3(0, 0, -1);
		case 3:
			return Vector3(1, 0, 0);
		case 4:
			return Vector3(-1, 0, 0);
		default:
			return Vector3(0, 1, 0);
	}
}

Quaternion NativeDiceThrowSolver::random_rotation() {
	return Quaternion::from_euler(Vector3(
			randf(0.0, Math_TAU),
			randf(0.0, Math_TAU),
			randf(0.0, Math_TAU)))
			.normalized();
}

Vector3 NativeDiceThrowSolver::lane_position(int p_index, int p_count, bool p_target_mode) const {
	int cols = static_cast<int>(Math::ceil(static_cast<real_t>(p_count) / 2.0));
	int col = p_index % cols;
	int row = static_cast<int>(Math::floor(static_cast<real_t>(p_index) / static_cast<real_t>(cols)));
	real_t spacing_x = 1.22;
	real_t spacing_z = 1.08;
	return Vector3(
			(static_cast<real_t>(col) - (static_cast<real_t>(cols) - 1.0) * 0.5) * spacing_x,
			0.0,
			(static_cast<real_t>(row) - 0.5) * spacing_z);
}

NativeDiceThrowSolver::ThrowParams NativeDiceThrowSolver::make_candidate(int p_index, int p_count, int p_target_value, const Dictionary &p_options) {
	bool target_mode = p_target_value >= 1 && p_target_value <= 6;
	Vector3 lane = lane_position(p_index, p_count, target_mode);
	real_t base_height = static_cast<real_t>(p_options.get("entry_height", target_mode ? 3.25 : 3.35));

	ThrowParams params;
	params.target_value = p_target_value;
	params.position = Vector3(
			lane.x + randf(-0.22, 0.22),
			base_height + static_cast<real_t>(p_index) * 0.1 + randf(0.0, 0.35),
			lane.z + randf(-0.22, 0.22));
	params.rotation = random_rotation();

	Vector3 outward(params.position.x, 0.0, params.position.z);
	if (outward.length_squared() < 0.001) {
		outward = Vector3(randf(-1.0, 1.0), 0.0, randf(-1.0, 1.0));
	}
	outward.normalize();
	Vector3 tangent(-outward.z, 0.0, outward.x);
	real_t radial_speed = randf(0.9, 1.2);
	real_t sideways_speed = randf(-1.35, 1.35);
	if (Math::abs(sideways_speed) < 0.65) {
		sideways_speed += sideways_speed >= 0.0 ? 0.65 : -0.65;
	}
	params.velocity = outward * radial_speed + tangent * sideways_speed;
	params.velocity.y = randf(-0.62, 0.18);

	params.angular_velocity = Vector3(randf(-10.8, 10.8), randf(-10.8, 10.8), randf(-10.8, 10.8));
	if (params.angular_velocity.length() < 6.0) {
		params.angular_velocity.y += params.angular_velocity.y >= 0.0 ? 6.5 : -6.5;
	}
	return params;
}

NativeDiceThrowSolver::ThrowParams NativeDiceThrowSolver::solve_single(int p_index, int p_count, int p_target_value, const Dictionary &p_options, const std::vector<ThrowParams> &p_selected) {
	if (p_target_value < 1 || p_target_value > 6) {
		ThrowParams random_params = make_candidate(p_index, p_count, 0, p_options);
		simulate(random_params);
		return random_params;
	}

	int attempts = static_cast<int>(static_cast<int64_t>(p_options.get("max_attempts_per_die", 96)));
	attempts = CLAMP(attempts, 8, 512);
	real_t min_final_separation = static_cast<real_t>(p_options.get("min_final_separation", 0.9));
	real_t min_path_separation = static_cast<real_t>(p_options.get("min_path_separation", 0.9));
	real_t min_table_margin = static_cast<real_t>(p_options.get("min_table_margin", 0.55));
	ThrowParams best;
	bool has_best = false;
	real_t best_score = -std::numeric_limits<real_t>::infinity();
	for (int attempt = 0; attempt < attempts; attempt++) {
		ThrowParams candidate = make_candidate(p_index, p_count, p_target_value, p_options);
		simulate(candidate);
		real_t separation = final_separation_score(candidate, p_selected);
		real_t path_separation = path_separation_score(candidate, p_selected);
		real_t table_margin = table_margin_score(candidate);
		real_t score = candidate.target_dot + CLAMP((separation - min_final_separation) * 0.35, -0.6, 0.6) + CLAMP((path_separation - min_path_separation) * 0.55, -0.9, 0.9) + CLAMP((table_margin - min_table_margin) * 0.45, -1.2, 0.7);
		if (candidate.predicted_value == p_target_value) {
			score += 10.0;
		}
		if (!has_best || score > best_score) {
			best = candidate;
			has_best = true;
			best_score = score;
		}
		if (candidate.predicted_value == p_target_value && separation >= min_final_separation && path_separation >= min_path_separation && table_margin >= min_table_margin) {
			simulate(candidate, true);
			return candidate;
		}
	}
	simulate(best, true);
	return best;
}

real_t NativeDiceThrowSolver::final_separation_score(const ThrowParams &p_candidate, const std::vector<ThrowParams> &p_selected) const {
	if (p_selected.empty()) {
		return std::numeric_limits<real_t>::infinity();
	}
	real_t min_distance = std::numeric_limits<real_t>::infinity();
	Vector2 candidate_xz(p_candidate.final_position.x, p_candidate.final_position.z);
	for (const ThrowParams &selected : p_selected) {
		Vector2 selected_xz(selected.final_position.x, selected.final_position.z);
		min_distance = MIN(min_distance, candidate_xz.distance_to(selected_xz));
	}
	return min_distance;
}

real_t NativeDiceThrowSolver::table_margin_score(const ThrowParams &p_candidate) const {
	const real_t safe_half_width = TABLE_WIDTH * 0.5 - 0.78;
	const real_t safe_half_depth = TABLE_DEPTH * 0.5 - 0.78;
	real_t min_margin = std::numeric_limits<real_t>::infinity();
	for (const Vector3 &position : p_candidate.path_positions) {
		if (position.y > 1.55) {
			continue;
		}
		real_t x_margin = safe_half_width - Math::abs(position.x);
		real_t z_margin = safe_half_depth - Math::abs(position.z);
		min_margin = MIN(min_margin, MIN(x_margin, z_margin));
	}
	if (min_margin == std::numeric_limits<real_t>::infinity()) {
		real_t x_margin = safe_half_width - Math::abs(p_candidate.final_position.x);
		real_t z_margin = safe_half_depth - Math::abs(p_candidate.final_position.z);
		min_margin = MIN(x_margin, z_margin);
	}
	return min_margin;
}

real_t NativeDiceThrowSolver::path_separation_score(const ThrowParams &p_candidate, const std::vector<ThrowParams> &p_selected) const {
	if (p_selected.empty()) {
		return std::numeric_limits<real_t>::infinity();
	}
	real_t min_distance = std::numeric_limits<real_t>::infinity();
	for (const ThrowParams &selected : p_selected) {
		size_t candidate_size = p_candidate.path_positions.size();
		size_t selected_size = selected.path_positions.size();
		if (candidate_size == 0 || selected_size == 0) {
			continue;
		}
		size_t max_size = MAX(candidate_size, selected_size);
		for (size_t i = 0; i < max_size; i++) {
			const Vector3 &candidate_pos = p_candidate.path_positions[MIN(i, candidate_size - 1)];
			const Vector3 &selected_pos = selected.path_positions[MIN(i, selected_size - 1)];
			real_t vertical = Math::abs(candidate_pos.y - selected_pos.y);
			if (vertical > DIE_SIZE * 0.92) {
				continue;
			}
			Vector2 candidate_xz(candidate_pos.x, candidate_pos.z);
			Vector2 selected_xz(selected_pos.x, selected_pos.z);
			min_distance = MIN(min_distance, candidate_xz.distance_to(selected_xz));
		}
	}
	return min_distance;
}

Dictionary NativeDiceThrowSolver::params_to_dictionary(const ThrowParams &p_params) const {
	Dictionary dict;
	dict["position"] = p_params.position;
	dict["quaternion"] = p_params.rotation;
	dict["velocity"] = p_params.velocity;
	dict["angular_velocity"] = p_params.angular_velocity;
	dict["trajectory"] = p_params.trajectory;
	dict["final_position"] = p_params.final_position;
	dict["final_quaternion"] = p_params.final_rotation;
	dict["target_value"] = p_params.target_value;
	dict["predicted_value"] = p_params.predicted_value;
	return dict;
}

void NativeDiceThrowSolver::simulate(ThrowParams &p_params, bool p_record_trajectory) {
	SimState state;
	state.position = p_params.position;
	state.rotation = p_params.rotation;
	state.velocity = p_params.velocity;
	state.angular_velocity = p_params.angular_velocity;
	p_params.trajectory.clear();
	p_params.path_positions.clear();
	p_params.path_positions.push_back(state.position);
	if (p_record_trajectory) {
		Dictionary initial_frame;
		initial_frame["position"] = state.position;
		initial_frame["quaternion"] = state.rotation;
		initial_frame["linear_speed"] = state.velocity.length();
		initial_frame["angular_speed"] = state.angular_velocity.length();
		p_params.trajectory.append(initial_frame);
	}

	const real_t dt = 1.0 / 120.0;
	for (int step = 0; step < 480; step++) {
		simulation_step(state, dt);
		if (p_record_trajectory && (step % 2 == 1)) {
			Dictionary frame;
			frame["position"] = state.position;
			frame["quaternion"] = state.rotation;
			frame["linear_speed"] = state.velocity.length();
			frame["angular_speed"] = state.angular_velocity.length();
			p_params.trajectory.append(frame);
		}
		if (step % 2 == 1) {
			p_params.path_positions.push_back(state.position);
		}
		if (state.position.y < 1.1 && state.velocity.length() < QUIET_LINEAR && state.angular_velocity.length() < QUIET_ANGULAR) {
			state.quiet_frames++;
			if (state.quiet_frames >= 36) {
				break;
			}
		} else {
			state.quiet_frames = 0;
		}
	}
	if (p_record_trajectory) {
		Dictionary final_frame;
		final_frame["position"] = state.position;
		final_frame["quaternion"] = state.rotation;
		final_frame["linear_speed"] = state.velocity.length();
		final_frame["angular_speed"] = state.angular_velocity.length();
		p_params.trajectory.append(final_frame);
	}
	if (p_params.path_positions.empty() || p_params.path_positions.back().distance_squared_to(state.position) > 0.0001) {
		p_params.path_positions.push_back(state.position);
	}
	p_params.final_position = state.position;
	p_params.final_rotation = state.rotation;
	p_params.predicted_value = get_up_face_value(state.rotation, &p_params.target_dot, p_params.target_value);
}

void NativeDiceThrowSolver::simulation_step(SimState &p_state, real_t p_dt) const {
	const real_t gravity = -19.0;
	const real_t linear_damp = 0.018;
	const real_t angular_damp = 0.038;
	p_state.velocity.y += gravity * p_dt;
	p_state.velocity *= Math::pow(1.0 - linear_damp, p_dt * 60.0);
	p_state.angular_velocity *= Math::pow(1.0 - angular_damp, p_dt * 60.0);

	p_state.position += p_state.velocity * p_dt;
	real_t angular_speed = p_state.angular_velocity.length();
	if (angular_speed > 0.0001) {
		Quaternion delta(p_state.angular_velocity / angular_speed, angular_speed * p_dt);
		p_state.rotation = (delta * p_state.rotation).normalized();
	}

	static const std::array<Vector3, 8> local_corners = {
		Vector3(-DIE_HALF, -DIE_HALF, -DIE_HALF),
		Vector3(-DIE_HALF, -DIE_HALF, DIE_HALF),
		Vector3(-DIE_HALF, DIE_HALF, -DIE_HALF),
		Vector3(-DIE_HALF, DIE_HALF, DIE_HALF),
		Vector3(DIE_HALF, -DIE_HALF, -DIE_HALF),
		Vector3(DIE_HALF, -DIE_HALF, DIE_HALF),
		Vector3(DIE_HALF, DIE_HALF, -DIE_HALF),
		Vector3(DIE_HALF, DIE_HALF, DIE_HALF),
	};

	const real_t half_width = TABLE_WIDTH * 0.5 - 0.36;
	const real_t half_depth = TABLE_DEPTH * 0.5 - 0.36;
	for (int iteration = 0; iteration < 4; iteration++) {
		for (const Vector3 &local_corner : local_corners) {
			Vector3 point = p_state.position + p_state.rotation.xform(local_corner);
			if (point.y < 0.0) {
				apply_contact(p_state, point, Vector3(0, 1, 0), -point.y, 0.34, 0.64);
			}
			if (point.x < -half_width) {
				apply_contact(p_state, point, Vector3(1, 0, 0), -half_width - point.x, 0.26, 0.58);
			} else if (point.x > half_width) {
				apply_contact(p_state, point, Vector3(-1, 0, 0), point.x - half_width, 0.26, 0.58);
			}
			if (point.z < -half_depth) {
				apply_contact(p_state, point, Vector3(0, 0, 1), -half_depth - point.z, 0.26, 0.58);
			} else if (point.z > half_depth) {
				apply_contact(p_state, point, Vector3(0, 0, -1), point.z - half_depth, 0.26, 0.58);
			}
		}
	}
}

void NativeDiceThrowSolver::apply_contact(SimState &p_state, const Vector3 &p_point, const Vector3 &p_normal, real_t p_penetration, real_t p_restitution, real_t p_friction) const {
	const real_t inv_mass = 1.0;
	const real_t inertia = (1.0 / 6.0) * DIE_SIZE * DIE_SIZE;
	const real_t inv_inertia = 1.0 / inertia;
	Vector3 r = p_point - p_state.position;
	Vector3 relative_velocity = p_state.velocity + p_state.angular_velocity.cross(r);
	real_t normal_speed = relative_velocity.dot(p_normal);
	if (normal_speed < 0.0) {
		Vector3 rn = r.cross(p_normal);
		real_t denom = inv_mass + (rn * inv_inertia).cross(r).dot(p_normal);
		if (denom > 0.00001) {
			real_t impulse_amount = -(1.0 + p_restitution) * normal_speed / denom;
			Vector3 impulse = p_normal * impulse_amount;
			p_state.velocity += impulse * inv_mass;
			p_state.angular_velocity += r.cross(impulse) * inv_inertia;

			Vector3 tangent_velocity = relative_velocity - p_normal * normal_speed;
			real_t tangent_speed = tangent_velocity.length();
			if (tangent_speed > 0.0001) {
				Vector3 tangent = tangent_velocity / tangent_speed;
				Vector3 rt = r.cross(tangent);
				real_t tangent_denom = inv_mass + (rt * inv_inertia).cross(r).dot(tangent);
				if (tangent_denom > 0.00001) {
					real_t tangent_impulse_amount = -tangent_speed / tangent_denom;
					real_t max_friction = impulse_amount * p_friction;
					tangent_impulse_amount = CLAMP(tangent_impulse_amount, -max_friction, max_friction);
					Vector3 tangent_impulse = tangent * tangent_impulse_amount;
					p_state.velocity += tangent_impulse * inv_mass;
					p_state.angular_velocity += r.cross(tangent_impulse) * inv_inertia;
				}
			}
		}
	}
	if (p_penetration > 0.0) {
		p_state.position += p_normal * (p_penetration * 0.38);
	}
}

int NativeDiceThrowSolver::get_up_face_value(const Quaternion &p_rotation, real_t *r_target_dot, int p_target_value) const {
	int best_value = 1;
	real_t best_dot = -1000.0;
	real_t target_dot = -1000.0;
	for (int value = 1; value <= 6; value++) {
		Vector3 normal = p_rotation.xform(face_normal(value));
		real_t dot = normal.dot(Vector3(0, 1, 0));
		if (value == p_target_value) {
			target_dot = dot;
		}
		if (dot > best_dot) {
			best_dot = dot;
			best_value = value;
		}
	}
	if (r_target_dot != nullptr) {
		*r_target_dot = p_target_value >= 1 && p_target_value <= 6 ? target_dot : best_dot;
	}
	return best_value;
}
