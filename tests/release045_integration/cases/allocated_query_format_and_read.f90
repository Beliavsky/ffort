program p
implicit none
character(:),allocatable::fmt,buf
integer::n,s
real(8)::v(2)
allocate(character(len=20)::fmt)
call get_command_argument(1,value=fmt,length=n,status=s)
if(s<=0.or.n/=0.or.fmt/='')error stop 1
fmt='(a,t8,f4.1)'
allocate(character(len=20)::buf)
buf='3 4'
read(buf,*)v
print fmt,'norm',norm2(v)
end program
