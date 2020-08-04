attribute vec2 position;
varying vec2 _uv;
void main(void)
{
  gl_Position = vec4(position, 0, 1);
  vec2 uv = position * 0.5 + 0.5;
  _uv = uv;
}