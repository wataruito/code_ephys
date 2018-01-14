path = '/home/wito/ubg-tera05/Recording/';

jobsDir = {
    'z_RIG01/2017-12-19_vm81a_base'
    'z_RIG01/2017-12-22_vm81a_base'
    'z_RIG02/2017-12-19_vm81b_base'
    'z_RIG02/2017-12-22_vm81b_base'
    };

for i = 1:4
    cd([path jobsDir{i}]);
    pipeline;
end


