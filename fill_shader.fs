#version 330

in vec2 fragTexCoord;
uniform sampler2D stencilTexture;
out vec4 finalColor;

void main() {
    vec4 tex = texture(stencilTexture, fragTexCoord);
    if (tex.r > 0.5) {
        finalColor = vec4(0.0, 0.8, 0.0, 0.5); // semi-transparent green
    } else {
        discard;
    }
}