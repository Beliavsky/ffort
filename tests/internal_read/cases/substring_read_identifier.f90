program p
implicit none
character(3)::read
read='abc'
read(2:2)='x'
if(read/='axc') stop 1
print *,1
end
