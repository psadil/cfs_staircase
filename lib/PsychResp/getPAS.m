function [ output_args ] = getPAS( window )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


reminder(1).pas = 'no image detected - 0';
reminder(2).pas = 'possibly saw, couldn''t name - 1';
reminder(3).pas = 'definitely saw, but unsure what it was (could possibly guess) - 2';
reminder(4).pas = 'saw something very clearly, could name - 3';

text_answer = 'Answer:  ';

% parameters
rosie.tCenter1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text1))/2  p.yCenter-450];
rosie.tCenter2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text2))/2  p.yCenter-410];
rosie.tCenter3 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text3))/2  p.yCenter-370];
rosie.tCenter4 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text4))/2  p.yCenter-330];

rosie.tCenter5 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text5))/2  p.yCenter-100];
rosie.tCenter6 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, rosie.text6))/2  p.yCenter-60];

answerBox = [p.xCenter-300 p.yCenter+150 p.xCenter+100 p.yCenter+550];


end

