implicit none
character(65536)::x(1)
integer::idx(129)
x='a'
idx=1
if(sum(index(x(idx),'a')+index(x(idx),'a'))/=258)error stop 'sum'
end
