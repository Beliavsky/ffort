implicit none
character(*),parameter::a(2)=[character(3)::"a","bc"],b(2)=a//"!"
print '(a)',a//":",b//":"
end
