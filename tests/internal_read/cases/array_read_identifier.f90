program p
implicit none
integer::read(3)
read=1
read(2)=4
read(1:1)=3
if(any(read/=[3,4,1])) stop 1
print *,1
end
