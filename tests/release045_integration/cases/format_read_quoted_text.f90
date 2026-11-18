program p
implicit none
integer::s
character(80)::line
character(24)::fmt
character(5)::label
real(8)::v(2)
line='"(a,t8,f4.1)" "norm" 3 4'
read(line,*,iostat=s)fmt,label,v
if(s/=0)error stop 1
print fmt,trim(label),norm2(v)
end program
