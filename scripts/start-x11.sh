until x11vnc -display ${DISPLAY} -rfbport ${RFB_PORT} ${X11VNC_PARAMS}; do
  echo "x11vnc server crashed with exit code $?.  Respawning.." >&2
  sleep 1
done