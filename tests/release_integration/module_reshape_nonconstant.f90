module m
integer::n=2
integer::a(2,2)=reshape([1,2,3,4],[n,n])
end module
program p
use m
end
