program p
implicit none
integer::s
character(80)::line
character(2)::words(2,1,2)
logical::mask(2,1,2)
line='"a" "b" "b " "z"'
read(line,*,iostat=s)words
if(s/=0)error stop 1
mask=lge(words,'b')
print '(i0,1x,4l1)',count(mask),mask
end program
