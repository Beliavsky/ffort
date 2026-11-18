program main
implicit none
real,target::a(6)
real,pointer::p(:)
a=[1.,2.,3.,4.,5.,6.]
p=>a
if(abs(norm2(p)-sqrt(91.))>2e-6) error stop 1
if(abs(norm2(p(6:1:-1))-sqrt(91.))>2e-6) error stop 2
end program
