#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/quaternion.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cstdint>
#include <random>
#include <vector>

namespace godot {

class NativeDiceThrowSolver : public RefCounted {
	GDCLASS(NativeDiceThrowSolver, RefCounted);

	struct ThrowParams {
		Vector3 position;
		Quaternion rotation;
		Vector3 velocity;
		Vector3 angular_velocity;
		Array trajectory;
		Vector3 final_position;
		Quaternion final_rotation;
		std::vector<Vector3> path_positions;
		int target_value = 0;
		int predicted_value = 0;
		real_t target_dot = -1.0;
	};

	struct SimState {
		Vector3 position;
		Quaternion rotation;
		Vector3 velocity;
		Vector3 angular_velocity;
		int quiet_frames = 0;
	};

	std::mt19937 rng;

protected:
	static void _bind_methods();

public:
	NativeDiceThrowSolver();

	Dictionary solve_throw(int32_t p_count, const Array &p_targets, const Dictionary &p_options = Dictionary());

private:
	static constexpr int MAX_DICE = 6;
	static constexpr real_t TABLE_WIDTH = 12.8;
	static constexpr real_t TABLE_DEPTH = 9.2;
	static constexpr real_t DIE_SIZE = 0.72;
	static constexpr real_t DIE_HALF = DIE_SIZE * 0.5;
	static constexpr real_t QUIET_LINEAR = 0.065;
	static constexpr real_t QUIET_ANGULAR = 0.11;

	int sanitize_target(const Variant &p_value) const;
	int random_pip();
	real_t randf(real_t p_min, real_t p_max);
	Vector3 face_normal(int p_value) const;
	Quaternion random_rotation();
	Vector3 lane_position(int p_index, int p_count, bool p_target_mode) const;
	ThrowParams make_candidate(int p_index, int p_count, int p_target_value, const Dictionary &p_options);
	ThrowParams solve_single(int p_index, int p_count, int p_target_value, const Dictionary &p_options, const std::vector<ThrowParams> &p_selected);
	real_t final_separation_score(const ThrowParams &p_candidate, const std::vector<ThrowParams> &p_selected) const;
	real_t path_separation_score(const ThrowParams &p_candidate, const std::vector<ThrowParams> &p_selected) const;
	real_t table_margin_score(const ThrowParams &p_candidate) const;
	Dictionary params_to_dictionary(const ThrowParams &p_params) const;
	void simulate(ThrowParams &p_params, bool p_record_trajectory = false);
	void simulation_step(SimState &p_state, real_t p_dt) const;
	void apply_contact(SimState &p_state, const Vector3 &p_point, const Vector3 &p_normal, real_t p_penetration, real_t p_restitution, real_t p_friction) const;
	int get_up_face_value(const Quaternion &p_rotation, real_t *r_target_dot = nullptr, int p_target_value = 0) const;
};

} // namespace godot
