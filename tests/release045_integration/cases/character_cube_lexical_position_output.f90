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
print '(a,t6,4l1)','mask',mask
end program
