import Foundation
import simd
import MediaPipeTasksVision // Нужен для Landmark

struct PoseValidator {

    // Допустимые отклонения (можно сделать настраиваемыми)
    let boneRatioTolerance: Float = 0.5
    let lengthRatioTolerance: Float = 0.7 // Более широкая для сравнения с торсом
    let minKneeAngle: Float = 5.0
    let maxKneeAngle: Float = 185.0
    let minElbowAngle: Float = 5.0
    let maxElbowAngle: Float = 185.0

    // Основной метод проверки
    func isPoseValid(landmarks: [Landmark]) -> Bool {
        // Проверка длин костей
        guard checkBoneLengthRatios(landmarks: landmarks) else { return false }
        // Проверка углов суставов
        guard checkJointAngles(landmarks: landmarks) else { return false }
        return true
    }

    // MARK: - Private Check Methods

    private func checkBoneLengthRatios(landmarks: [Landmark]) -> Bool {
        guard let torsoLength = getAverageTorsoLength(landmarks: landmarks) else { return true }
        if torsoLength < 0.1 { return true }

        // Ноги
        if let leftThigh = getLength(PoseConnections.LandmarkIndex.leftHip, PoseConnections.LandmarkIndex.leftKnee, landmarks: landmarks),
           let leftShin = getLength(PoseConnections.LandmarkIndex.leftKnee, PoseConnections.LandmarkIndex.leftAnkle, landmarks: landmarks) {
            if !isRatioValid(leftThigh, leftShin, boneRatioTolerance) { /*print("[Pose Check FAIL] Left Leg Ratio");*/ return false }
            if !isLengthValid(leftThigh + leftShin, relativeTo: torsoLength * 1.5, tolerance: lengthRatioTolerance) { /*print("[Pose Check FAIL] Left Leg Length");*/ return false }
        }
        if let rightThigh = getLength(PoseConnections.LandmarkIndex.rightHip, PoseConnections.LandmarkIndex.rightKnee, landmarks: landmarks),
           let rightShin = getLength(PoseConnections.LandmarkIndex.rightKnee, PoseConnections.LandmarkIndex.rightAnkle, landmarks: landmarks) {
            if !isRatioValid(rightThigh, rightShin, boneRatioTolerance) { /*print("[Pose Check FAIL] Right Leg Ratio");*/ return false }
            if !isLengthValid(rightThigh + rightShin, relativeTo: torsoLength * 1.5, tolerance: lengthRatioTolerance) { /*print("[Pose Check FAIL] Right Leg Length");*/ return false }
        }

        // Руки
        if let leftUpperArm = getLength(PoseConnections.LandmarkIndex.leftShoulder, PoseConnections.LandmarkIndex.leftElbow, landmarks: landmarks),
           let leftForearm = getLength(PoseConnections.LandmarkIndex.leftElbow, PoseConnections.LandmarkIndex.leftWrist, landmarks: landmarks) {
            if !isRatioValid(leftUpperArm, leftForearm, boneRatioTolerance) { /*print("[Pose Check FAIL] Left Arm Ratio");*/ return false }
            if !isLengthValid(leftUpperArm + leftForearm, relativeTo: torsoLength * 1.2, tolerance: lengthRatioTolerance) { /*print("[Pose Check FAIL] Left Arm Length");*/ return false }
        }
         if let rightUpperArm = getLength(PoseConnections.LandmarkIndex.rightShoulder, PoseConnections.LandmarkIndex.rightElbow, landmarks: landmarks),
           let rightForearm = getLength(PoseConnections.LandmarkIndex.rightElbow, PoseConnections.LandmarkIndex.rightWrist, landmarks: landmarks) {
            if !isRatioValid(rightUpperArm, rightForearm, boneRatioTolerance) { /*print("[Pose Check FAIL] Right Arm Ratio");*/ return false }
            if !isLengthValid(rightUpperArm + rightForearm, relativeTo: torsoLength * 1.2, tolerance: lengthRatioTolerance) { /*print("[Pose Check FAIL] Right Arm Length");*/ return false }
        }

        return true
    }

    private func checkJointAngles(landmarks: [Landmark]) -> Bool {
        // Колени
        if let leftKneeAngle = getAngle(.leftHip, .leftKnee, .leftAnkle, landmarks: landmarks) {
            if leftKneeAngle < minKneeAngle || leftKneeAngle > maxKneeAngle { /*print("[Pose Check FAIL] Left Knee Angle: \(leftKneeAngle)")*/ return false }
        }
        if let rightKneeAngle = getAngle(.rightHip, .rightKnee, .rightAnkle, landmarks: landmarks) {
            if rightKneeAngle < minKneeAngle || rightKneeAngle > maxKneeAngle { /*print("[Pose Check FAIL] Right Knee Angle: \(rightKneeAngle)")*/ return false }
        }
        // Локти
         if let leftElbowAngle = getAngle(.leftShoulder, .leftElbow, .leftWrist, landmarks: landmarks) {
             if leftElbowAngle < minElbowAngle || leftElbowAngle > maxElbowAngle { /*print("[Pose Check FAIL] Left Elbow Angle: \(leftElbowAngle)")*/ return false }
        }
        if let rightElbowAngle = getAngle(.rightShoulder, .rightElbow, .rightWrist, landmarks: landmarks) {
            if rightElbowAngle < minElbowAngle || rightElbowAngle > maxElbowAngle { /*print("[Pose Check FAIL] Right Elbow Angle: \(rightElbowAngle)")*/ return false }
        }
        return true
    }

    // --- Вспомогательные функции ---

    private func getAverageTorsoLength(landmarks: [Landmark]) -> Float? {
        let leftTorso = getLength(PoseConnections.LandmarkIndex.leftShoulder, PoseConnections.LandmarkIndex.leftHip, landmarks: landmarks)
        let rightTorso = getLength(PoseConnections.LandmarkIndex.rightShoulder, PoseConnections.LandmarkIndex.rightHip, landmarks: landmarks)
        if let lt = leftTorso, let rt = rightTorso { return (lt + rt) / 2.0 }
        if let lt = leftTorso { return lt }
        if let rt = rightTorso { return rt }
        return nil
    }

    private func getLength(_ p1IndexName: PoseConnections.LandmarkIndex, _ p2IndexName: PoseConnections.LandmarkIndex, landmarks: [Landmark]) -> Float? {
         let p1Idx = p1IndexName.rawValue
         let p2Idx = p2IndexName.rawValue
         guard p1Idx < landmarks.count, p2Idx < landmarks.count else { return nil }
         let p1 = simd_float3(landmarks[p1Idx].x, landmarks[p1Idx].y, landmarks[p1Idx].z)
         let p2 = simd_float3(landmarks[p2Idx].x, landmarks[p2Idx].y, landmarks[p2Idx].z)
         return simd_distance(p1, p2)
    }

    private func isRatioValid(_ len1: Float, _ len2: Float, _ tolerance: Float) -> Bool {
        guard len1 > 0.01, len2 > 0.01 else { return true }
        let ratio = len1 / len2
        return ratio >= (1.0 - tolerance) && ratio <= (1.0 + tolerance)
    }

    private func isLengthValid(_ length: Float, relativeTo referenceLength: Float, tolerance: Float) -> Bool {
        guard length > 0.01, referenceLength > 0.01 else { return true }
        let ratio = length / referenceLength
        return ratio >= (1.0 - tolerance) && ratio <= (1.0 + tolerance)
    }

    private func getAngle(_ p1IndexName: PoseConnections.LandmarkIndex, _ p2IndexName: PoseConnections.LandmarkIndex, _ p3IndexName: PoseConnections.LandmarkIndex, landmarks: [Landmark]) -> Float? {
         let p1Idx = p1IndexName.rawValue; let p2Idx = p2IndexName.rawValue; let p3Idx = p3IndexName.rawValue
         guard p1Idx < landmarks.count, p2Idx < landmarks.count, p3Idx < landmarks.count else { return nil }
         let p1 = landmarks[p1Idx]; let p2 = landmarks[p2Idx]; let p3 = landmarks[p3Idx]
         let v1 = simd_float3(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z)
         let v2 = simd_float3(p3.x - p2.x, p3.y - p2.y, p3.z - p2.z)
         let v1Norm = simd_normalize(v1); let v2Norm = simd_normalize(v2)
         if v1Norm.x.isNaN || v2Norm.x.isNaN { return nil }
         let dot = simd_dot(v1Norm, v2Norm)
         let clampedDot = max(-1.0, min(1.0, dot))
          return acos(clampedDot) * (180.0 / .pi)
    }
}
