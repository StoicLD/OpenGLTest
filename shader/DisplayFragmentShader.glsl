varying vec2 _uv;
uniform sampler2D to;

void main()
{
  gl_FragColor = texture2D(to, _uv);
  //gl_FragColor = texture2D(to, vec2(_uv.x, 1.0 - _uv.y));
}