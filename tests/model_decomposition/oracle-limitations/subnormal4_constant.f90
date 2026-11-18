program p
implicit none
real::x,a,b
x=tiny(1.)/2
a=set_exponent(.5,-148);b=set_exponent(.75,-149)
print *,fraction(x),exponent(x),a,b
print *,fraction(a),exponent(a),set_exponent(.5,-149),set_exponent(.75,-150)
print *,sign(1.,set_exponent(-.75,-150))
end program
