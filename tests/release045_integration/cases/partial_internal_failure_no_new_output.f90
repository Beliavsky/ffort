program p
implicit none
integer::s
character(80)::line
character(5)::word
real(8)::v(2)
write(*,'(a,t2,a)',advance='no')'ABCD','x'
line='"hello" bad 4'
read(line,*,iostat=s)word,v
if(s<=0)error stop 1
print '(a)',word
end program
