#version 330
uniform sampler2D texture0;
uniform vec3 point_1;
uniform vec3 point_2;
uniform vec3 point_3;
uniform vec3 point_4;
uniform vec3 point_5;
uniform vec3 point_6;
uniform vec3 point_7;
uniform vec3 point_8;
uniform vec2 resolution;
in vec2 out_uvs; // get the uv (1,1) size of the layer
vec2 textUvs = vec2(out_uvs.x, 1-out_uvs.y);
out vec4 fragColorOut;

#define ROT_XYZ 0
#define ROT_ZYX 1
#define ROT_YXZ 2
#define ROT_ZXY 3
#define ROT_YZX 4
#define ROT_XZY 5

vec4 qMul(vec4 q1, vec4 q2) {
    float w1 = q1.x, x1 = q1.y, y1 = q1.z, z1 = q1.w;
    float w2 = q2.x, x2 = q2.y, y2 = q2.z, z2 = q2.w;

    return vec4(
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2, // w
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2, // x
        w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2, // y
        w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2  // z
    );
}

vec4 qFromEuler(vec3 eulerAngles, int order) {
    float phi = eulerAngles.x * 0.5;
    float theta = eulerAngles.y * 0.5;
    float psi = eulerAngles.z * 0.5;

    float cX = cos(phi);
    float cY = cos(theta);
    float cZ = cos(psi);
    float sX = sin(phi);
    float sY = sin(theta);
    float sZ = sin(psi);

    if (order == ROT_XYZ) {
        return vec4(
            cX * cY * cZ - sX * sY * sZ,
            sX * cY * cZ + sY * sZ * cX,
            sY * cX * cZ - sX * sZ * cY,
            sX * sY * cZ + sZ * cX * cY
        );
    } else if (order == ROT_ZYX) {
        return vec4(
            sX * sY * sZ + cX * cY * cZ,
            sZ * cX * cY - sX * sY * cZ,
            sX * sZ * cY + sY * cX * cZ,
            sX * cY * cZ - sY * sZ * cX
        );
    } else if (order == ROT_YXZ) {
        return vec4(
            sX * sY * sZ + cX * cY * cZ,
            sX * sZ * cY + sY * cX * cZ,
            sX * cY * cZ - sY * sZ * cX,
            sZ * cX * cY - sX * sY * cZ
        );
    } else if (order == ROT_ZXY) {
        return vec4(
            cX * cY * cZ - sX * sY * sZ,
            sY * cX * cZ - sX * sZ * cY,
            sX * sY * cZ + sZ * cX * cY,
            sX * cY * cZ + sY * sZ * cX
        );
    } else if (order == ROT_YZX) {
        return vec4(
            cX * cY * cZ - sX * sY * sZ,
            sX * sY * cZ + sZ * cX * cY,
            sX * cY * cZ + sY * sZ * cX,
            sY * cX * cZ - sX * sZ * cY
        );
    } else if (order == ROT_XZY) {
        return vec4(
            sX * sY * sZ + cX * cY * cZ,
            sX * cY * cZ - sY * sZ * cX,
            sZ * cX * cY - sX * sY * cZ,
            sX * sZ * cY + sY * cX * cZ
        );
    } else {
        // Error: unsupported order
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
}

vec4 qFromEulerLogical(float phi, float theta, float psi, int order) {
      return qFromEuler(vec3(psi, theta, phi), ROT_XYZ);
}

float asinFunc(float t) {
    return (t >= 1.0) ? 3.14159265359 / 2.0 : (t <= -1.0) ? -3.14159265359 / 2.0 : asin(t);
}

vec3 qToEuler(vec4 q, int order) {
    float w = q.x, x = q.y, y = q.z, z = q.w;

    float wx = w * x, wy = w * y, wz = w * z;
    float xx = x * x, xy = x * y, xz = x * z;
    float yy = y * y, yz = y * z, zz = z * z;

    if (order == ROT_XYZ) {
        return vec3(
            -atan(2.0 * (yz - wx), 1.0 - 2.0 * (xx + yy)),
            asinFunc(2.0 * (xz + wy)),
            -atan(2.0 * (xy - wz), 1.0 - 2.0 * (yy + zz))
        );
    } else if (order == ROT_ZYX) {
        return vec3(
            atan(2.0 * (xy + wz), 1.0 - 2.0 * (yy + zz)),
            -asinFunc(2.0 * (xz - wy)),
            atan(2.0 * (yz + wx), 1.0 - 2.0 * (xx + yy))
        );
    } else if (order == ROT_YXZ) {
        return vec3(
            atan(2.0 * (xz + wy), 1.0 - 2.0 * (xx + zz)),
            -asinFunc(2.0 * (yz - wx)),
            atan(2.0 * (xy + wz), 1.0 - 2.0 * (xx + zz))
        );
    } else if (order == ROT_ZXY) {
        return vec3(
            -atan(2.0 * (xz - wy), 1.0 - 2.0 * (xx + yy)),
            asinFunc(2.0 * (yz + wx)),
            -atan(2.0 * (xy - wz), 1.0 - 2.0 * (xx + zz))
        );
    } else if (order == ROT_YZX) {
        return vec3(
            atan(2.0 * (yz + wx), 1.0 - 2.0 * (xx + zz)),
            asinFunc(2.0 * (xy - wz)),
            atan(2.0 * (xz + wy), 1.0 - 2.0 * (yy + zz))
        );
    } else if (order == ROT_XZY) {
        return vec3(
            -atan(2.0 * (yz + wx), 1.0 - 2.0 * (xx + zz)),
            -asinFunc(2.0 * (xy - wz)),
            -atan(2.0 * (xz + wy), 1.0 - 2.0 * (yy + zz))
        );
    } else {
        // Error: unsupported order
        return vec3(0.0, 0.0, 0.0);
    }
}

vec3 getCord(float x, float y, float z, float rX, float rY, float distance) {

    float endX = x + distance * sin(rY);
    float endY = y - distance * sin(rX) * cos(rY);
    float endZ = z + distance * cos(rX) * cos(rY);

    return vec3(endX, endY, endZ);
}

void main(void)
{
    // Position
    float x = point_1.x;
    float y = point_2.x;
    float z = point_3.x;
    
    // FOV
    float hFOV = point_7.x;
    float vFOV = point_8.x;
    float focalLengthX = resolution.x / (2.0 * tan(radians(hFOV) / 2.0));
    float focalLengthY = resolution.y / (2.0 * tan(radians(vFOV) / 2.0));
    
    // Rotations
    float centerOffsetX = (out_uvs.x - 0.5) * resolution.x;
    float centerOffsetY = (out_uvs.y - 0.5) * resolution.y;
    float rX = point_4.x;
    float rY = point_5.x;
    float rZ = point_6.x;
    float rXoffset = degrees(atan(centerOffsetY / focalLengthY));
    float rYoffset = degrees(atan(centerOffsetX / focalLengthX));

    // New orientation (converting local rotations to global using quaternions)
    vec4 qG = qFromEulerLogical(radians(rZ), radians(rY), radians(rX), ROT_ZYX);
    vec4 qL = qFromEulerLogical(0, radians(rYoffset), radians(rXoffset), ROT_ZYX);
    vec4 q = qMul(qG, qL);
    vec3 finalOrientation = qToEuler(q, ROT_XYZ);

    // Orientation debug
    // float xRg = 15;
    // float yRg = -10;
    // float zRg = 30;
    // float xRl = 15;
    // float yRl = -10;
    // float zRl = 30;
    // vec4 qG = qFromEulerLogical(radians(zRg), radians(yRg), radians(xRg), ROT_ZYX);
    // vec4 qL = qFromEulerLogical(radians(zRl), radians(yRl), radians(xRl), ROT_ZYX);
    // vec4 q = qMul(qG, qL);
    
    // Distance
    float far = 25000;
    vec4 textureInput = texture(texture0,textUvs);
    float centerDistance = textureInput.x * far;
    float realDistance = centerDistance / (cos(radians(rYoffset)) * cos(radians(rXoffset)));
    
    // Output
    vec3 coordinates = getCord(x, y, z, finalOrientation.x, finalOrientation.y, realDistance);
    fragColorOut = vec4(coordinates, 1);
    
    // Debug
    //vec3 finalOrientationDeg = vec3(degrees(finalOrientation.x), degrees(finalOrientation.y), degrees(finalOrientation.z));
    //fragColorOut = vec4(realDistance, realDistance, realDistance, 1);
}

// Debug
// void main(void)
// {
//     fragColorOut = vec4(1, 1, 1, 1);
// }