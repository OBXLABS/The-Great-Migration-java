/**
 * Touch delegate for PQLabs touchscreen.
 Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class MigrationTouchDelegate implements TouchDelegate {
    Migration parent;
  
    public MigrationTouchDelegate(Migration p) {
      parent = p;
    }
    
    public int OnTouchFrame(int frame_id, int time_stamp, Vector/*<TouchPoint>*/ point_list) {
        TouchPoint point;
        for(int i = 0; i < point_list.size(); i++)
        {
          point = (TouchPoint)point_list.elementAt(i);
          
          switch (point.m_point_event) {
            case PQMTClientConstant.TP_DOWN:
                mousePressed(point);
                break;
            case PQMTClientConstant.TP_MOVE:
                mouseDragged(point);
                break;
            case PQMTClientConstant.TP_UP:
                mouseReleased(point);
                break;
          }
        }
    
        return PQMTClientConstant.PQ_MT_SUCESS;    
    }

    /**
     * Adds the current point to the path if the mouse button 1 is pressed
     *
     * @param event the mouse event
     */
    public void mousePressed(TouchPoint point) {
      parent.mousePressed(point.m_id, point.m_x, point.m_y);
    }

    
    /**
     * Clears the path if the mouse button 1 is released
     *
     * @param event the mouse event
     */
    public void mouseReleased(TouchPoint point) {
      parent.mouseReleased(point.m_id, point.m_x, point.m_y);
    }
    
    
    /**
     * Updates the local mouse coordinates and adds points to the path
     *
     * @param event the mouse event
     */
    public void mouseDragged(TouchPoint point) {
      parent.mouseDragged(point.m_id, point.m_x, point.m_y);
    }
    
    public int OnTouchGesture(TouchGesture touch_gesture) {
        return PQMTClientConstant.PQ_MT_SUCESS;
    }
}
